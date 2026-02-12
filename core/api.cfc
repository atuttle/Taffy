component hint="Your Application.cfc should extend this class" {

	// this method is meant to be (optionally) overridden in your application.cfc
	function getEnvironment() output="false" hint="override this function to define the current API environment" {
		return "";
	}

	/**
	 * onTaffyRequest gives you the opportunity to inspect the request before it is sent to the service.
	 * If you override this function, you MUST either return TRUE or a representation object
	 * (eg either taffy.core.nativeJsonSerializer or your default representation class)
	 */
	function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers, methodMetadata, matchedURI) output="false" {
		return true;
	}

	/**
	 * onTaffyRequestEnd gives you the opportunity to access the request after it has been processed by the service.
	 * If you override this function, you MUST either return TRUE or a representation object
	 * (eg either taffy.core.nativeJsonSerializer or your default representation class)
	 */
	function onTaffyRequestEnd(verb, cfc, requestArguments, mimeExt, headers, methodMetadata, matchedURI, parsedResponse, originalResponse, statusCode) output="false" {
		return true;
	}

	// override these functions to implement caching hooks
	function validCacheExists(cacheKey) output="false" {
		return false;
	}

	function setCachedResponse(cacheKey, data) output="false" {
	}

	function getCachedResponse(cacheKey) output="false" {
	}

	function getCacheKey(cfc, requestArguments, matchedURI) output="false" {
		return arguments.matchedURI & "_" & arguments.requestArguments.hashCode();
	}

	// Your Application.cfc should override this method AND call super.onApplicationStart()
	function onApplicationStart() {
		var before = getTickCount();
		var after = 0;
		setupFramework();
		checkEngineSupport();
		after = getTickCount();
		addTaffyHeader("X-TIME-TO-RELOAD", after - before);
		return true;
	}

	// Your Application.cfc should override this method AND call super.onRequestStart(targetpath)
	function onRequestStart(targetPath = "") {
		var local = {};
		request.unhandled = false;
		local.reloadedInThisRequest = false;
		request.taffyReloaded = false;

		// this will probably happen if taffy is sharing an app name with an existing application so that you can use its application context
		if (!structKeyExists(application, "_taffy")) {
			onApplicationStart();
			local.reloadedInThisRequest = true;
		}

		// allow reloading
		if (
			(
				structKeyExists(url, application._taffy.settings.reloadKey)
				&& url[application._taffy.settings.reloadKey] == application._taffy.settings.reloadPassword
			)
			|| application._taffy.settings.reloadOnEveryRequest == true
		) {
			if (!local.reloadedInThisRequest && !isUnhandledPathRequest(arguments.targetPath)) {
				// prevent double reloads
				onApplicationStart();
			}
		}

		if (!isUnhandledPathRequest(arguments.targetPath)) {
			// if browsing to root of api, show dashboard
			local.path = replaceNoCase(cgi.path_info, cgi.script_name, "");
			if (
				!structKeyExists(url, application._taffy.settings.endpointURLParam)
				&& !structKeyExists(form, application._taffy.settings.endpointURLParam)
				&& len(local.path) <= 1
				&& listFindNoCase(cgi.script_name, "index.cfm", "/") == listLen(cgi.script_name, "/")
			) {
				if (!application._taffy.settings.disableDashboard) {
					if (structKeyExists(url, "docs")) {
						include template=application._taffy.settings.docsPath;
					} else {
						include "../dashboard/dashboard.cfm";
					}
					abort;
				} else {
					if (len(application._taffy.settings.disabledDashboardRedirect)) {
						location(url=application._taffy.settings.disabledDashboardRedirect, addtoken=false);
						abort;
					} else if (application._taffy.settings.showDocsWhenDashboardDisabled == false) {
						throwError(403, "Forbidden");
					}
				}
			}
		} else {
			// allow pass-thru for selected paths
			structDelete(this, "onRequest");
			structDelete(variables, "onRequest");
			request.unhandled = true;
		}

		return true;
	}

	// If you choose to override this function, consider calling super.onError(exception)
	function onError(exception) {
		var data = {};
		var root = "";
		var logger = "";

		try {
			if (structKeyExists(request, "unhandled") && request.unhandled == true) {
				return super.onError(arguments.exception);
			}

			logger = createObject("component", application._taffy.settings.exceptionLogAdapter).init(
				application._taffy.settings.exceptionLogAdapterConfig
			);
			logger.saveLog(exception);

			// return 500 no matter what
			cfheader(statuscode=500, statustext="Error");
			cfcontent(reset=true);

			if (structKeyExists(exception, "rootCause")) {
				root = exception.rootCause;
			} else {
				root = exception;
			}

			if (structKeyExists(root, "TagContext")) {
				data.stacktrace = root.tagContext;
			}

			if (application._taffy.settings.returnExceptionsAsJson == true) {
				// try to find the relevant details
				if (structKeyExists(root, "message")) {
					data.error = root.message;
				}
				if (structKeyExists(root, "detail")) {
					data.detail = root.detail;
				}
				if (structKeyExists(root, "tagContext")) {
					data.tagContext = root.tagContext[1].template & " [Line #root.tagContext[1].line#]";
				}
				// MAKE IT LOOK GOOD!
				setting showdebugoutput=false enablecfoutputonly=true;
				cfcontent(type="application/json; charset=utf-8");
				writeOutput(serializeJson(data));
			}
		} catch (any cfcatch) {
			cfcontent(reset=true, type="text/plain; charset=utf-8");
			cfheader(statuscode=500, statustext="Error");
			var errorMsg = "An unhandled exception occurred: ";
			if (isStruct(root) && structKeyExists(root, "message")) {
				errorMsg &= root.message;
			} else {
				errorMsg &= root;
			}
			if (isStruct(root) && structKeyExists(root, "detail")) {
				errorMsg &= " -- " & root.detail;
			}
			writeOutput(errorMsg);
			writeDump(var=cfcatch, format="text", label="ERROR WHEN LOGGING EXCEPTION");
			writeDump(var=exception, format="text", label="ORIGINAL EXCEPTION");
		}
	}

	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	// short-circuit logic
	function onRequest(required string targetPage) output="true" returntype="boolean" {
		var _taffyRequest = {};
		var local = {};
		var m = "";
		var sampler = "";
		request._taffyRequest = _taffyRequest;
		local.debug = false;

		_taffyRequest.metrics = {};
		m = _taffyRequest.metrics;
		m.init = getTickCount();

		// enable/disable debug output per settings
		if (!structKeyExists(url, application._taffy.settings.debugKey)) {
			setting showdebugoutput=false;
		}

		// display api dashboard if requested
		if (
			!structKeyExists(url, application._taffy.settings.endpointURLParam)
			&& !structKeyExists(form, application._taffy.settings.endpointURLParam)
			&& len(cgi.path_info) <= 1
			&& listFindNoCase(cgi.script_name, "index.cfm", "/") == listLen(cgi.script_name, "/")
		) {
			if (!application._taffy.settings.disableDashboard) {
				if (structKeyExists(url, "docs")) {
					include template=application._taffy.settings.docsPath;
				} else {
					include "../dashboard/dashboard.cfm";
				}
				abort;
			} else {
				if (len(application._taffy.settings.disabledDashboardRedirect)) {
					location(url=application._taffy.settings.disabledDashboardRedirect, addtoken=false);
					abort;
				} else if (application._taffy.settings.showDocsWhenDashboardDisabled) {
					include template=application._taffy.settings.docsPath;
					abort;
				} else {
					throwError(403, "Forbidden");
				}
			}
		}

		// get request details
		m.beforeParse = getTickCount();
		local.parsed = parseRequest();
		m.afterParse = getTickCount();
		structAppend(_taffyRequest, local.parsed);
		m.parseTime = m.afterParse - m.beforeParse;

		// CORS headers (so that CORS can pass even if the resource throws an exception)
		local.allowVerbs = uCase(structKeyList(_taffyRequest.matchDetails.methods));
		if (
			(application._taffy.settings.allowCrossDomain == true || len(application._taffy.settings.allowCrossDomain) > 0)
			&& listFindNoCase("PUT,PATCH,DELETE,OPTIONS", _taffyRequest.verb)
			&& !listFind(local.allowVerbs, "OPTIONS")
		) {
			local.allowVerbs = listAppend(local.allowVerbs, "OPTIONS");
		}

		if (structKeyExists(_taffyRequest.headers, "origin") && (application._taffy.settings.allowCrossDomain == true || len(application._taffy.settings.allowCrossDomain) > 0)) {
			if (application._taffy.settings.allowCrossDomain == true) {
				cfheader(name="Access-Control-Allow-Origin", value="*");
			} else {
				// The Access-Control-Allow-Origin header can only have 1 value so we check to see if the Origin header is
				// in the list of origins specified in the config setting and parrot back the Origin header if so.
				// We also need to add the Access-Control-Allow-Credentials header and set it to true for those type requests
				local.domains = listToArray(application._taffy.settings.allowCrossDomain, ", ;");
				if (structKeyExists(_taffyRequest.headers, "origin")) {
					for (local.i = 1; local.i <= arrayLen(local.domains); local.i++) {
						if (lcase(rereplace(_taffyRequest.headers.origin, "(http|https):\/\/", "", "all")) == lcase(rereplace(local.domains[local.i], "(http|https):\/\/", "", "all"))) {
							cfheader(name="Access-Control-Allow-Origin", value=_taffyRequest.headers.origin);
							cfheader(name="Access-Control-Allow-Credentials", value="true");
							break;
						}
					}
				}
			}
			cfheader(name="Access-Control-Allow-Methods", value=local.allowVerbs);
			// Why do we parrot back these headers? See: https://github.com/atuttle/Taffy/issues/144
			if (!structKeyExists(_taffyRequest.headers, "Access-Control-Request-Headers")) {
				cfheader(name="Access-Control-Allow-Headers", value="Origin, Authorization, X-CSRF-Token, X-Requested-With, Content-Type, X-HTTP-Method-Override, Accept, Referrer, User-Agent");
			} else {
				// parrot back all of the request headers to allow the request to continue (can we improve on this?)
				local.allowedHeaders = {};
				for (local.h in listToArray("Origin,Authorization,X-CSRF-Token,X-Requested-With,Content-Type,X-HTTP-Method-Override,Accept,Referrer,User-Agent")) {
					local.allowedHeaders[local.h] = 1;
				}
				local.requestedHeaders = _taffyRequest.headers["Access-Control-Request-Headers"];
				for (local.i in listToArray(local.requestedHeaders)) {
					local.allowedHeaders[local.i] = 1;
				}
				cfheader(name="Access-Control-Allow-Headers", value=structKeyList(local.allowedHeaders));
			}
		}

		// global headers
		addHeaders(getGlobalHeaders());

		// Now we know everything we need to know to service the request. let's service it!

		// ...after we let the api developer know all of the request details first...
		m.beforeOnTaffyRequest = getTickCount();
		_taffyRequest.continue = onTaffyRequest(
			_taffyRequest.verb,
			_taffyRequest.matchDetails.beanName,
			_taffyRequest.requestArguments,
			_taffyRequest.returnMimeExt,
			_taffyRequest.headers,
			_taffyRequest.methodMetadata,
			local.parsed.matchDetails.srcUri
		);
		m.afterOnTaffyRequest = getTickCount();
		m.otrTime = m.afterOnTaffyRequest - m.beforeOnTaffyRequest;

		if (!structKeyExists(_taffyRequest, "continue")) {
			// developer forgot to return true
			throw(
				message="Error in your onTaffyRequest method",
				detail="Your onTaffyRequest method returned no value. Expected: Return TRUE or call noData()/representationOf().",
				errorcode="400"
			);
		}

		if (isObject(_taffyRequest.continue)) {
			// inspection complete but request has been aborted by developer; return custom response
			_taffyRequest.result = duplicate(_taffyRequest.continue);
			structDelete(_taffyRequest, "continue");
			m.resourceTime = 0;
		} else {
			// inspection complete and request allowed by developer

			// handle requests for simulated responses
			if (structKeyExists(_taffyRequest.requestArguments, application._taffy.settings.simulateKey) && _taffyRequest.requestArguments[application._taffy.settings.simulateKey] == application._taffy.settings.simulatePassword) {
				// is there a simulated response?
				sampler = "sample#_taffyRequest.method#Response";
				if (structKeyExists(_taffyRequest.matchDetails.metadata, sampler)) {
					// get simulated response
					_taffyRequest.result = invoke(
						application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName),
						sampler
					);
					_taffyRequest.result = rep(_taffyRequest.result);
				} else {
					// no method for simulated response, so return 400
					_taffyRequest.result = noData().withStatus(400, "No Sample Response Available");
				}
			} else {
				// send request to service
				if (structKeyExists(_taffyRequest.matchDetails.methods, _taffyRequest.verb)) {
					// check the cache before we call the resource
					m.cacheCheckTime = getTickCount();
					local.cacheKey = getCacheKey(
						_taffyRequest.matchDetails.beanName,
						_taffyRequest.requestArguments,
						local.parsed.matchDetails.srcUri
					);
					if (ucase(_taffyRequest.verb) == "GET" && validCacheExists(local.cacheKey)) {
						m.cacheCheckTime = getTickCount() - m.cacheCheckTime;
						m.cacheGetTime = getTickCount();
						_taffyRequest.result = getCachedResponse(local.cacheKey);
						m.cacheGetTime = m.cacheGetTime - getTickCount();
					} else {
						if (ucase(_taffyRequest.verb) == "GET") {
							m.cacheCheckTime = getTickCount() - m.cacheCheckTime;
						} else {
							structDelete(m, "cacheCheckTime");
						}
						// returns a representation-object
						m.beforeResource = getTickCount();
						_taffyRequest.result = invoke(
							application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName),
							_taffyRequest.method,
							_taffyRequest.requestArguments
						);
						m.afterResource = getTickCount();
						m.resourceTime = m.afterResource - m.beforeResource;
						if (!isDefined("_taffyRequest.result")) {
							throw(
								message="Resource did not return a value",
								detail="The resource is expected to return a call to rep()/representationOf() or noData(). It appears there was no return at all.",
								errorcode="taffy.resources.ResourceReturnsNothing"
							);
						}
						// If the type returned is not an instance of baseSerializer, wrap it with a call to rep().
						// This way we can directly return the object instead of a serializer from resource actions.
						if (!isInstanceOf(_taffyRequest.result, "taffy.core.baseSerializer")) {
							_taffyRequest.result = rep(_taffyRequest.result);
						}
						if (ucase(_taffyRequest.verb) == "GET" && structKeyExists(local, "cacheKey")) {
							m.cacheSaveStart = getTickCount();
							setCachedResponse(local.cacheKey, _taffyRequest.result);
							m.cacheSaveTime = getTickCount() - m.cacheSaveStart;
						}
					}
				} else if (!listFind(local.allowVerbs, _taffyRequest.verb)) {
					// if the verb is not implemented, refuse the request
					cfheader(name="ALLOW", value=local.allowVerbs);
					throwError(405, "Method Not Allowed");
				} else {
					// create dummy response for cross domain OPTIONS request
					_taffyRequest.resultHeaders = {};
					_taffyRequest.statusArgs = {};
					_taffyRequest.statusArgs.statusCode = 200;
					_taffyRequest.statusArgs.statusText = "OK";
				}
			}
		}

		// make sure the requested mime type is available
		if (!mimeSupported(_taffyRequest.returnMimeExt)) {
			throwError(400, "Requested format not available (#_taffyRequest.returnMimeExt#)");
		}

		if (structKeyExists(_taffyRequest, "result")) {
			// get status code
			_taffyRequest.statusArgs = {};
			_taffyRequest.statusArgs.statusCode = _taffyRequest.result.getStatus();
			_taffyRequest.statusArgs.statusText = _taffyRequest.result.getStatusText();
			// get custom headers
			_taffyRequest.resultHeaders = invoke(_taffyRequest.result, "getHeaders");
		}

		setting enablecfoutputonly=true;
		cfcontent(reset=true, type="#getReturnMimeAsHeader(_taffyRequest.returnMimeExt)#; charset=utf-8");
		cfheader(statuscode=_taffyRequest.statusArgs.statusCode, statustext=_taffyRequest.statusArgs.statusText);

		// headers
		addHeaders(_taffyRequest.resultHeaders);

		// add ALLOW header for current resource, which describes available verbs
		cfheader(name="ALLOW", value=local.allowVerbs);

		// metrics headers that should always apply
		addTaffyHeader("X-TIME-IN-PARSE", m.parseTime);
		addTaffyHeader("X-TIME-IN-ONTAFFYREQUEST", m.otrTime);
		if (structKeyExists(m, "resourceTime")) {
			addTaffyHeader("X-TIME-IN-RESOURCE", m.resourceTime);
		}
		if (structKeyExists(m, "cacheCheckTime")) {
			addTaffyHeader("X-TIME-IN-CACHE-CHECK", m.cacheCheckTime);
		}
		if (structKeyExists(m, "cacheGetTime")) {
			addTaffyHeader("X-TIME-IN-CACHE-GET", m.cacheGetTime);
		}
		if (structKeyExists(m, "cacheSaveTime")) {
			addTaffyHeader("X-TIME-IN-CACHE-SAVE", m.cacheSaveTime);
		}

		if (application._taffy.settings.exposeHeaders) {
			local.exposeHeaderList = structKeyList(_taffyRequest.resultHeaders);
			local.exposeHeaderValue = "";
			if (application._taffy.settings.useEtags && _taffyRequest.verb == "GET" && _taffyRequest.result.getType() == "textual") {
				local.exposeHeaderList = listAppend(local.exposeHeaderList, "Etag");
			}
			for (local.exposeHeader in listToArray(local.exposeHeaderList)) {
				// filter out default simple response headers: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers
				if (!listFindNoCase("Cache-Control,Content-Language,Content-Type,Expires,Last-Modified,Pragma", local.exposeHeader)) {
					local.exposeHeaderValue = listAppend(local.exposeHeaderValue, local.exposeHeader);
				}
			}
			if (listLen(local.exposeHeaderValue) > 0) {
				cfheader(name="Access-Control-Expose-Headers", value=local.exposeHeaderValue);
			}
		}

		// result data
		if (structKeyExists(_taffyRequest, "result")) {
			_taffyRequest.resultType = _taffyRequest.result.getType();
			local.resultSerialized = "";

			if (_taffyRequest.resultType == "textual") {
				// serialize the representation's data into the requested mime type
				_taffyRequest.metrics.beforeSerialize = getTickCount();
				_taffyRequest.resultSerialized = invoke(
					_taffyRequest.result,
					"getAs#_taffyRequest.returnMimeExt#"
				);
				_taffyRequest.metrics.afterSerialize = getTickCount();
				m.serializeTime = m.afterSerialize - m.beforeSerialize;
				addTaffyHeader("X-TIME-IN-SERIALIZE", m.serializeTime);

				// apply jsonp wrapper if requested
				if (structKeyExists(_taffyRequest, "jsonpCallback")) {
					_taffyRequest.resultSerialized = _taffyRequest.jsonpCallback & "(" & _taffyRequest.resultSerialized & ");";
				}

				// don't return data if etags are enabled and the data hasn't changed
				if (application._taffy.settings.useEtags && _taffyRequest.verb == "GET") {
					// etag values are quoted per: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
					if (structKeyExists(server, "lucee")) {
						// hashCode() will not work for lucee, see issue #354
						_taffyRequest.serverEtag = '"' & hash(_taffyRequest.resultSerialized) & '"';
					} else {
						_taffyRequest.serverEtag = '"' & _taffyRequest.result.getData().hashCode() & '"';
					}
					if (structKeyExists(_taffyRequest.headers, "If-None-Match")) {
						_taffyRequest.clientEtag = _taffyRequest.headers["If-None-Match"];

						if (len(_taffyRequest.clientEtag) > 0 && _taffyRequest.clientEtag == _taffyRequest.serverEtag) {
							cfheader(statuscode=304, statustext="Not Modified");
							cfcontent(reset=true, type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8");
							return true;
						} else {
							cfheader(name="Etag", value=_taffyRequest.serverEtag);
						}
					} else {
						cfheader(name="Etag", value=_taffyRequest.serverEtag);
					}
				}

				m.done = getTickCount();
				m.taffyTime = m.done - m.init - m.parseTime - m.otrTime - m.serializeTime;
				if (structKeyExists(m, "resourceTime")) {
					m.taffyTime -= m.resourceTime;
				}
				addTaffyHeader("X-TIME-IN-TAFFY", m.taffyTime);

				cfcontent(reset=true, type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8");
				if (_taffyRequest.resultSerialized != ('"' & '"')) {
					local.resultSerialized = _taffyRequest.resultSerialized;
				}
				// debug output
				if (structKeyExists(url, application._taffy.settings.debugKey)) {
					local.debug = true;
				}

			} else if (_taffyRequest.resultType == "filename") {
				m.done = getTickCount();
				m.taffyTime = m.done - m.init - m.parseTime - m.otrTime - m.resourceTime;
				addTaffyHeader("X-TIME-IN-TAFFY", m.taffyTime);
				cfcontent(reset=true, file=_taffyRequest.result.getFileName(), type=_taffyRequest.result.getFileMime(), deletefile=_taffyRequest.result.getDeleteFile());

			} else if (_taffyRequest.resultType == "filedata") {
				m.done = getTickCount();
				m.taffyTime = m.done - m.init - m.parseTime - m.otrTime - m.resourceTime;
				addTaffyHeader("X-TIME-IN-TAFFY", m.taffyTime);
				cfcontent(reset=true, variable=_taffyRequest.result.getFileData(), type=_taffyRequest.result.getFileMime());

			} else if (_taffyRequest.resultType == "imagedata") {
				m.done = getTickCount();
				m.taffyTime = m.done - m.init - m.parseTime - m.otrTime - m.resourceTime;
				addTaffyHeader("X-TIME-IN-TAFFY", m.taffyTime);
				cfcontent(reset=true, variable=_taffyRequest.result.getImageData(), type=_taffyRequest.result.getFileMime());
			}
		}

		local.resultSerialized = "";
		if (structKeyExists(_taffyRequest, "resultSerialized")) {
			local.resultSerialized = _taffyRequest.resultSerialized;
		}

		local.result = {};
		if (structKeyExists(_taffyRequest, "result")) {
			local.result = _taffyRequest.result.getData();
		}

		// ...after the service has finished...
		m.beforeOnTaffyRequestEnd = getTickCount();
		onTaffyRequestEnd(
			_taffyRequest.verb,
			_taffyRequest.matchDetails.beanName,
			_taffyRequest.requestArguments,
			_taffyRequest.returnMimeExt,
			_taffyRequest.headers,
			_taffyRequest.methodMetadata,
			local.parsed.matchDetails.srcUri,
			local.resultSerialized,
			local.result,
			_taffyRequest.statusArgs.statusCode
		);
		m.otreTime = getTickCount() - m.beforeOnTaffyRequestEnd;
		addTaffyHeader("X-TIME-IN-ONTAFFYREQUESTEND", m.otreTime);

		if (len(trim(local.resultSerialized))) {
			writeOutput(local.resultSerialized);
		}
		// debug output
		if (local.debug) {
			writeOutput("<h3>Request Details:</h3>");
			writeDump(var=_taffyRequest);
		}

		return true;
	}

	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	// internal methods
	private void function checkEngineSupport() output="false" {
		application._taffy.compat = {
			queryToStruct: "missing",
			queryToArray: "missing"
		};
		var funcs = getFunctionList();
		if (structKeyExists(funcs, "queryToStruct")) {
			application._taffy.compat.queryToStruct = "exists";
		}
		if (structKeyExists(funcs, "queryToArray")) {
			application._taffy.compat.queryToArray = "exists";
		}
	}

	private void function setupFramework() output="false" {
		var local = {};
		param name="variables.framework" default={};
		request.taffyReloaded = true;
		local._taffy = {};
		local._taffy.version = "4.0.0";
		local._taffy.endpoints = {};

		// default settings
		local.defaultConfig = {};
		local.defaultConfig.resourcesCFCPath = "";
		local.defaultConfig.docs = {};
		local.defaultConfig.docs.APIName = "Your API Name (variables.framework.docs.APIName)";
		local.defaultConfig.docs.APIVersion = "0.0.0 (variables.framework.docs.APIVersion)";
		local.defaultConfig.docsPath = "../dashboard/docs.cfm";
		local.defaultConfig.defaultMime = "";
		local.defaultConfig.debugKey = "debug";
		local.defaultConfig.reloadKey = "reload";
		local.defaultConfig.reloadPassword = "true";
		local.defaultConfig.reloadOnEveryRequest = false;
		local.defaultConfig.simulateKey = "sampleResponse";
		local.defaultConfig.simulatePassword = "true";
		local.defaultConfig.endpointURLParam = "endpoint";
		local.defaultConfig.serializer = "taffy.core.nativeJsonSerializer";
		local.defaultConfig.deserializer = "taffy.core.nativeJsonDeserializer";
		local.defaultConfig.disableDashboard = false;
		local.defaultConfig.disabledDashboardRedirect = "";
		local.defaultConfig.dashboardHeaders = {};
		local.defaultConfig.showDocsWhenDashboardDisabled = false;
		local.defaultConfig.unhandledPaths = "/flex2gateway";
		local.defaultConfig.allowCrossDomain = false;
		local.defaultConfig.useEtags = false;
		local.defaultConfig.exposeHeaders = false;
		local.defaultConfig.jsonp = false;
		local.defaultConfig.noDataSends204NoContent = false;
		local.defaultConfig.exposeTaffyHeaders = true;
		local.defaultConfig.globalHeaders = {};
		local.defaultConfig.mimeTypes = {};
		local.defaultConfig.returnExceptionsAsJson = true;
		local.defaultConfig.exceptionLogAdapter = "taffy.bonus.LogToDevNull";
		local.defaultConfig.exceptionLogAdapterConfig = {};
		local.defaultConfig.csrfToken = {};
		local.defaultConfig.csrfToken.cookieName = "";
		local.defaultConfig.csrfToken.headerName = "";
		local.defaultConfig.allowGoogleFonts = true;

		// status
		local._taffy.status = {};
		local._taffy.status.internalBeanFactoryUsed = false;
		local._taffy.status.externalBeanFactoryUsed = false;
		local._taffy.uriMatchOrder = [];

		// allow setting overrides
		local._taffy.settings = {};
		structAppend(local._taffy.settings, local.defaultConfig, true); // initialize to default values
		structAppend(local._taffy.settings, variables.framework, true); // update with user values

		// allow environment-specific config
		local.env = getEnvironment();
		if (len(local.env) > 0) {
			param name="variables.framework" default={};
			param name="variables.framework.environments" default={};
			if (structKeyExists(variables.framework.environments, local.env) && isStruct(variables.framework.environments[local.env])) {
				structAppend(local._taffy.settings, variables.framework.environments[local.env]);
			}
		}

		// bean factory definition
		if (structKeyExists(variables.framework, "beanFactory")) {
			if (isSimpleValue(variables.framework.beanFactory) && len(variables.framework.beanFactory) == 0) {
				// if the BF value is "" doing nothing with it
			} else {
				local._taffy.externalBeanFactory = variables.framework.beanFactory;
				local._taffy.status.externalBeanFactoryUsed = true;
			}
		}

		// translate unhandledPaths config to regex for easier matching (This is ripped off from FW/1. Thanks, Sean!)
		local._taffy.settings.unhandledPathsRegex = replaceNoCase(
			REReplace(local._taffy.settings.unhandledPaths, "(\+|\*|\?|\.|\[|\^|\$|\(|\)|\{|\||\\)", "\\\1", "all"),
			",", "|", "all"
		);

		// if resources folder exists, use internal bean factory
		local.resourcePath = guessResourcesFullPath(local._taffy.settings.resourcesCFCPath);
		local.noResources = false;
		if (directoryExists(local.resourcePath)) {
			// setup internal bean factory
			local._taffy.factory = createObject("component", "taffy.core.factory");
			if (structKeyExists(local._taffy, "externalBeanFactory")) {
				local._taffy.factory.init(local._taffy.externalBeanFactory);
			} else {
				local._taffy.factory.init();
			}
			local._taffy.factory.loadBeansFromPath(local.resourcePath, guessResourcesCFCPath(local._taffy.settings.resourcesCFCPath), local.resourcePath, true, local._taffy);
			local._taffy.beanList = local._taffy.factory.getBeanList();
			local._taffy.endpoints = cacheBeanMetaData(local._taffy.factory, local._taffy.beanList, local._taffy);
			local._taffy.status.internalBeanFactoryUsed = true;
		} else if (local._taffy.status.externalBeanFactoryUsed) {
			// only using external factory, so create a pointer to it
			local._taffy.factory = local._taffy.externalBeanFactory;
			// since external factory is only factory, check it for taffy resources
			local.beanList = getBeanListFromExternalFactory(local._taffy.externalBeanFactory);
			local._taffy.endpoints = cacheBeanMetaData(local._taffy.externalBeanFactory, local.beanList, local._taffy);
		} else {
			local.noResources = true;
		}

		if (!local.noResources) {
			// sort URIs
			local._taffy.URIMatchOrder = sortURIMatchOrder(local._taffy.endpoints);
			// automatically introspect mime types from cfc metadata of default representation class
			local.mimetypes = inspectMimeTypes(local._taffy.settings.serializer, local._taffy.factory);
			structAppend(local._taffy.settings, local.mimeTypes);
			// check to make sure a default mime type is set
			if (local._taffy.settings.defaultMime == "") {
				throwError(400, "You have not specified a default mime type!");
			}
		}

		// inspect the deserializer to find out what contentTypes are supported
		local._taffy.contentTypes = getSupportedContentTypes(local._taffy.settings.deserializer);
		// hot-swap!
		application._taffy = local._taffy;

		// we must write the header *after* we have initialized our settings
		addTaffyHeader("X-TAFFY-RELOADED", true);
	}

	private struct function parseRequest() output="false" {
		var requestObj = {};
		var tmp = 0;
		var local = {};

		// Check for method tunnelling by clients unable to send PUT/DELETE requests (e.g. Flash Player);
		// Actual desired method will be contained in a special header
		var httpMethodOverride = "null";
		try {
			httpMethodOverride = GetPageContext().getRequest().getHeader("X-HTTP-Method-Override");
		} catch (any e) {
		}

		requestObj.uri = getPath();
		if (!len(requestObj.uri)) {
			if (structKeyExists(url, application._taffy.settings.endpointURLParam)) {
				requestObj.uri = urlDecode(url[application._taffy.settings.endpointURLParam]);
			} else if (structKeyExists(form, application._taffy.settings.endpointURLParam)) {
				requestObj.uri = urlDecode(form[application._taffy.settings.endpointURLParam]);
			}
		}

		// check for format in the URI
		requestObj.uriFormat = formatFromURI(requestObj.uri);

		// attempt to find the cfc for the requested uri
		requestObj.matchingRegex = matchURI(requestObj.uri);

		// uri doesn't map to any known resources
		if (!len(requestObj.matchingRegex)) {
			throwError(404, "Not Found");
		}

		// get the cfc name and token array for the matching regex
		requestObj.matchDetails = application._taffy.endpoints[requestObj.matchingRegex];

		// which verb is requested?
		requestObj.verb = cgi.request_method;

		// Should we override the actual method based on method tunnelling?
		if (isDefined("httpMethodOverride") && !isNull(httpMethodOverride) && httpMethodOverride != "null") {
			requestObj.verb = httpMethodOverride;
		}

		if (structKeyExists(application._taffy.endpoints[requestObj.matchingRegex].methods, requestObj.verb)) {
			requestObj.method = application._taffy.endpoints[requestObj.matchingRegex].methods[requestObj.verb];
		} else {
			requestObj.method = "";
		}

		requestObj.body = getRequestBody();
		requestObj.contentType = cgi.content_type;
		if (len(requestObj.body) && requestObj.body != "null") {
			if (findNoCase("multipart/form-data", requestObj.contentType)) {
				// do nothing, to support the way railo handles multipart requests (just avoids the error condition below)
				requestObj.queryString = cgi.query_string;
			} else {
				if (contentTypeIsSupported(requestObj.contentType)) {
					requestObj.bodyArgs = getDeserialized(requestObj.body, requestObj.contentType);
					requestObj.queryString = cgi.query_string;
				} else {
					if (isJson(requestObj.body)) {
						throwError(400, "Looks like you're sending JSON data, but you haven't specified a content type. Aborting request.");
					} else {
						throwError(400, "You must specify a content-type. Aborting request.");
					}
				}
			}
		} else {
			// actual query parameters
			requestObj.queryString = cgi.query_string;
		}

		// grab request headers
		requestObj.headers = getHTTPRequestData().headers;

		// build the argumentCollection to pass to the cfc
		requestObj.requestArguments = buildRequestArguments(
			requestObj.matchingRegex,
			requestObj.matchDetails.tokens,
			requestObj.uri,
			requestObj.queryString,
			requestObj.headers
		);
		// include any deserialized body params
		if (structKeyExists(requestObj, "bodyArgs")) {
			structAppend(requestObj.requestArguments, requestObj.bodyArgs);
		}
		// also capture form POST data (higher priority that url variables of same name)
		structAppend(requestObj.requestArguments, form);

		// if JSONP is enabled, capture the requested callback name
		if (application._taffy.settings.jsonp != false) {
			if (structKeyExists(requestObj.requestArguments, application._taffy.settings.jsonp)) {
				// variables.framework.jsonp contains the callback parameter name
				requestObj.jsonpCallback = requestObj.requestArguments[application._taffy.settings.jsonp];
			}
		}

		// use requested mime type or the default
		requestObj.returnMimeExt = "";
		if (structKeyExists(requestObj.requestArguments, "_taffy_mime")) {
			requestObj.returnMimeExt = requestObj.requestArguments._taffy_mime;
			if (left(requestObj.returnMimeExt, 1) == ".") {
				requestObj.returnMimeExt = right(requestObj.returnMimeExt, len(requestObj.returnMimeExt) - 1);
			}
			if (requestObj.returnMimeExt == "*/*") {
				requestObj.returnMimeExt = application._taffy.settings.defaultMime;
			}
			if (!structKeyExists(application._taffy.settings.mimeExtensions, requestObj.returnMimeExt)) {
				throwError(400, "Requested mime type is not supported (#requestObj.returnMimeExt#)");
			}
		} else if (requestObj.uriFormat != "") {
			requestObj.returnMimeExt = requestObj.uriFormat;
		} else {
			// run some checks on the default
			if (application._taffy.settings.defaultMime == "") {
				throwError(400, "You have not specified a default mime type");
			} else if (!structKeyExists(application._taffy.settings.mimeExtensions, application._taffy.settings.defaultMime)) {
				throwError(400, "Your default mime type (#application._taffy.settings.defaultMime#) is not implemented");
			}
			requestObj.returnMimeExt = application._taffy.settings.defaultMime;
		}
		structDelete(requestObj.requestArguments, "_taffy_mime");

		// get the method metadata (if any) for onTaffyRequest
		if (requestObj.method != "") {
			requestObj.methodMetadata = application._taffy.endpoints[requestObj.matchingRegex].metadata[requestObj.method];
		} else {
			// method will be "" when un-implemented method is requested (e.g. OPTIONS)
			requestObj.methodMetadata = {};
		}

		return requestObj;
	}

	private function formatFromURI(uri) output="false" {
		var local = {};
		for (local.mime in application._taffy.settings.mimeExtensions) {
			if (right(arguments.uri, len(local.mime) + 1) == "." & local.mime) {
				return local.mime;
			}
		}
		return "";
	}

	private function convertURItoRegex(required string uri) output="false" {
		var local = {};

		local.uriChunks = listToArray(arguments.uri, "/");
		local.returnData = {};
		local.returnData.tokens = [];
		local.uriMatcher = "";

		local.regexes = {};
		local.regexes.segment = "([^\/]+)"; // anything but a slash
		local.regexes.segmentWithOptFormat = "(?:(?:([^\/\.]+)(?:\.)([a-zA-Z0-9]+))\/?|([^\/\.]+))";
		local.regexes.optFormatWithOptSlash = "((?:\.)[^\.\?\/]+)?\/?" // for ".json[/]" support

		/*
			above regex explained:
			(?:
				(?:
					([^\/]+)(?:\.)([a-zA-Z0-9]+)      --foo.json
				)
				\/?                                   --optional trailing slash
				|(                                    --or
					([^\/]+)                          --foo
				)
			)

			we make it this complicated so that we can capture the ".json" separately from the "foo"
			... fucking regex, man!
		*/

		for (local.chunk in local.uriChunks) {
			if (left(local.chunk, 1) != "{" || right(local.chunk, 1) != "}") {
				// not a token
				local.uriMatcher = local.uriMatcher & "/" & local.chunk;
			} else {
				// strip {curly braces}
				local.chunk = left(right(local.chunk, len(local.chunk) - 1), len(local.chunk) - 2);
				// it's a token... but which kind?
				if (find(":", local.chunk) != 0) {
					local.pattern = "(" & listRest(local.chunk, ":") & ")"; // make sure we capture the value
					local.tokenName = listFirst(local.chunk, ":");
				} else {
					local.pattern = local.regexes.segment;
					local.tokenName = local.chunk;
				}
				local.uriMatcher = local.uriMatcher & "/" & local.pattern;
				arrayAppend(local.returnData.tokens, local.tokenName);
			}
		}

		// if uriRegex ends with a token, slip the format piece in there too...
		local.uriRegex = "^" & local.uriMatcher;
		if (right(local.uriRegex, 8) == local.regexes.segment) {
			local.uriRegex = left(local.uriRegex, len(local.uriRegex) - 8) & local.regexes.segmentWithOptFormat;
		}

		// require the uri to terminate after specified content
		local.uriRegex = local.uriRegex & local.regexes.optFormatWithOptSlash & "$";

		local.returnData.uriRegex = local.uriRegex;
		return local.returnData;
	}

	private function sortURIMatchOrder(endpoints) output="false" {
		var URIMatchOrder = listToArray(structKeyList(arguments.endpoints, chr(10)), chr(10));
		arraySort(URIMatchOrder, "textnocase", "desc");
		return URIMatchOrder;
	}

	private string function matchURI(required string requestedURI) output="false" {
		var local = {};
		local.uriCount = arrayLen(application._taffy.URIMatchOrder);
		for (local.i = 1; local.i <= local.uriCount; local.i++) {
			local.attempt = reMatchNoCase(application._taffy.URIMatchOrder[local.i], arguments.requestedURI);
			if (arrayLen(local.attempt) > 0) {
				// found our mapping
				return application._taffy.URIMatchOrder[local.i];
			}
		}
		// nothing found
		return "";
	}

	private function getRequestBody() output="false" hint="Gets request body data, which CF doesn't do automatically for some verbs" {
		// Special thanks to Jason Dean (@JasonPDean) and Ray Camden (@ColdFusionJedi) who helped me figure out how to do this
		var body = getHTTPRequestData().content;
		// on input with content-type "application/json" CF seems to expose it as binary data. Here we convert it back to plain text
		if (isBinary(body)) {
			body = charsetEncode(body, "UTF-8");
		}
		return body;
	}

	private function contentTypeIsSupported(string contentType) output="false" {
		var ct = listFirst(arguments.contentType, ";");
		return structKeyExists(application._taffy.contentTypes, ct);
	}

	private function getDeserialized(required body, required contentType) output="false" {
		var ct = listFirst(arguments.contentType, ";");
		var fn = application._taffy.contentTypes[ct];
		var args = {};
		var result = {};
		args.body = arguments.body;

		result = invoke(application._taffy.settings.deserializer, fn, args);
		return result;
	}

	private function getSupportedContentTypes(deserializer) output="false" hint="must be the full dot-notation path to the component" {
		return _recurse_getSupportedContentTypes(getComponentMetadata(arguments.deserializer));
	}

	private function _recurse_getSupportedContentTypes(objMetaData) output="false" {
		var local = {};
		local.response = {};
		// recurse into parents first so that children override parents
		if (structKeyExists(arguments.objMetaData, "extends")) {
			local.response = _recurse_getSupportedContentTypes(arguments.objMetaData.extends);
		}
		// then handle child settings
		if (structKeyExists(arguments.objMetaData, "functions") && isArray(arguments.objMetaData.functions)) {
			local.funcs = arguments.objMetaData.functions;
			for (local.f = 1; local.f <= arrayLen(local.funcs); local.f++) {
				// for every function whose name starts with "getFrom" *and* has a taffy_mime metadata attribute, count it
				local.mime = "";
				if (structKeyExists(local.funcs[local.f], "taffy_mime")) {
					local.mime = local.funcs[local.f].taffy_mime;
				} else if (structKeyExists(local.funcs[local.f], "taffy:mime")) {
					local.mime = local.funcs[local.f]["taffy:mime"];
				}
				if (ucase(left(local.funcs[local.f].name, 7)) == "GETFROM" && len(local.mime)) {
					for (local.m in listToArray(local.mime, ",;")) {
						local.response[local.m] = local.funcs[local.f].name;
					}
				}
			}
		}
		return local.response;
	}

	private struct function buildRequestArguments(required string regex, required array tokenNamesArray, required string uri, required string queryString, required struct headers) output="false" hint="regex that describes the request (including uri and query string parameters)" {
		var local = {};
		var tmp = "";
		local.returnData = {}; // this will be used as an argumentCollection for the method that ultimately gets called

		// parse path_info data into key-value pairs
		local.tokenValues = reFindNoSuck(arguments.regex, arguments.uri);
		local.numTokenValues = arrayLen(local.tokenValues);
		local.numTokenNames = arrayLen(arguments.tokenNamesArray);
		if (local.numTokenNames > 0) {
			for (local.t = 1; local.t <= local.numTokenNames; local.t++) {
				local.returnData[arguments.tokenNamesArray[local.t]] = urlDecode(local.tokenValues[local.t]);
			}
		}
		// query_string input is also key-value pairs
		for (local.t in listToArray(arguments.queryString, "&")) {
			local.qsKey = urlDecode(listFirst(local.t, "="));
			local.qsValue = "";
			if (listLen(local.t, "=") == 2) {
				local.qsValue = urlDecode(listLast(local.t, "="));
			}
			if ((len(local.qsKey) > 2) && (right(local.qsKey, 2) == "[]")) {
				local.qsKey = left(local.qsKey, len(local.qsKey) - 2);
				if (!structKeyExists(local.returnData, local.qsKey)) {
					local.returnData[local.qsKey] = [];
				}
				arrayAppend(local.returnData[local.qsKey], local.qsValue);
			} else {
				local.returnData[local.qsKey] = local.qsValue;
			}
		}
		// if a mime type is requested as part of the url ("whatever.json"), then extract that so taffy can use it
		if (local.numTokenValues > local.numTokenNames) {
			// when there is 1 more token value than name, that value (regex capture group) is the format
			local.mime = local.tokenValues[local.numTokenValues];
			local.returnData["_taffy_mime"] = local.mime;
		} else if (structKeyExists(arguments.headers, "Accept")) {
			local.headerMatch = false;
			for (tmp in listToArray(arguments.headers.accept)) {
				// deal with that q=0 stuff (just ignore it)
				if (listLen(tmp, ";") > 1) {
					tmp = listFirst(tmp, ";");
				}
				if (structKeyExists(application._taffy.settings.mimeTypes, tmp)) {
					local.returnData["_taffy_mime"] = application._taffy.settings.mimeTypes[tmp];
					local.headerMatch = true;
					break; // exit loop
				} else if (trim(tmp) == "*/*") {
					local.returnData["_taffy_mime"] = application._taffy.settings.defaultMime;
					local.headerMatch = true;
					break; // exit loop
				}
			}
			// if a header is passed, but it didn't match any known mimes, and no mime was found via extension, just use whatever's in the header
			if (local.headerMatch == false) {
				local.returnData["_taffy_mime"] = listFirst(listFirst(arguments.headers.accept, ","), ";");
			}
		}
		return local.returnData;
	}

	private string function guessResourcesPath() output="false" hint="used to try and figure out the absolute path of the /resources folder even though this file may not be in the web root" {
		var local = {};
		// if /resources has been explicitly defined in an server/application mapping, it should take precedence
		if (directoryExists(expandPath("resources"))) {
			return "resources";
		} else if (directoryExists(expandPath("/resources"))) {
			return "/resources";
		}

		// if all else fails, fall through to guessing where /resources lives
		local.indexcfmpath = cgi.script_name;
		local.resourcesPath = listDeleteAt(local.indexcfmpath, listLen(local.indexcfmpath, "/"), "/") & "/resources";

		if (GetContextRoot() != "") {
			local.resourcesPath = ReReplace(local.resourcesPath, "^#GetContextRoot()#", "");
		}

		return local.resourcesPath;
	}

	private string function guessResourcesFullPath(string dottedPath = "") output="false" hint="dotted path to a resource folder to use" {
		// when we have an explicit path, no need to make a guess, we just need to convert the dotted path to a file path
		if (len(arguments.dottedPath)) {
			return expandPath("/" & replace(arguments.dottedPath, ".", "/", "all"));
		}

		return expandPath(guessResourcesPath());
	}

	private string function guessResourcesCFCPath(string dottedPath = "") output="false" hint="dotted path to a resource folder to use" {
		var path = "";
		// when we have an explicit path, no need to make a guess
		if (len(arguments.dottedPath)) {
			return arguments.dottedPath;
		}

		path = guessResourcesPath();
		if (left(path, 1) == "/") {
			path = right(path, len(path) - 1);
		}
		return reReplace(path, "\/", ".", "all");
	}

	private void function throwError(numeric statusCode = 500, required string msg, struct headers = {}) output="false" hint="message to return to api consumer" {
		cfcontent(reset=true);
		addHeaders(arguments.headers);
		cfheader(statuscode=arguments.statusCode, statustext=arguments.msg);
		abort;
	}

	private array function splitURIs(required string input) output="false" {
		var inBracketCount = 0;
		var output = [];
		var s = createObject("java", "java.lang.StringBuffer").init("");
		var c = "";
		for (c in trim(input).toCharArray()) {
			if (c == "{") {
				inBracketCount += 1;
			} else if (c == "}" && inBracketCount > 0) {
				inBracketCount -= 1;
			}
			if (c == "," && inBracketCount == 0) {
				arrayAppend(output, s.toString());
				s.setLength(0);
			} else {
				s.append(c);
			}
		}
		if (s.length() > 0) {
			arrayAppend(output, s.toString());
		}
		return output;
	}

	private void function throwExceptionIfURIDoesntBeginWithForwardSlash(required string uri, required string beanName) output="false" {
		var uriDoesntBeginWithForwardSlash = left(arguments.uri, 1) != "/";

		if (uriDoesntBeginWithForwardSlash) {
			throw(
				message="URI doesn't begin with a forward slash.",
				detail="The URI (#arguments.uri#) for `#arguments.beanName#` should begin with a forward slash.",
				errorcode="taffy.resources.URIDoesntBeginWithForwardSlash"
			);
		}
	}

	private function cacheBeanMetaData(required factory, required string beanList, required any taffyRef) output="false" {
		var local = {};
		local.endpoints = {};
		for (local.beanName in listToArray(arguments.beanList)) {
			// get the cfc metadata that defines the uri for that cfc
			local.cfcMetadata = getMetaData(arguments.factory.getBean(local.beanName));
			local.uriAttr = "";
			if (structKeyExists(local.cfcMetadata, "taffy_uri")) {
				local.uriAttr = local.cfcMetadata["taffy_uri"];
			} else if (structKeyExists(local.cfcMetadata, "taffy:uri")) {
				local.uriAttr = local.cfcMetadata["taffy:uri"];
			}

			local.uris = splitURIs(local.uriAttr);

			if (structKeyExists(local.cfcMetaData, "taffy:aopbean")) {
				local.cachedBeanName = local.cfcMetaData["taffy:aopbean"];
			} else if (structKeyExists(local.cfcMetaData, "taffy_aopbean")) {
				local.cachedBeanName = local.cfcMetaData["taffy_aopbean"];
			} else {
				local.cachedBeanName = local.beanName;
			}

			// if it doesn't have any uris, then it's not a resource
			if (arrayLen(local.uris)) {
				for (local.uri in local.uris) {
					try {
						local.uri = trim(local.uri);
						local.metaInfo = convertURItoRegex(local.uri);
						if (structKeyExists(local.endpoints, local.metaInfo.uriRegex)) {
							throw(
								message="Duplicate URI scheme detected. All URIs must be unique (excluding tokens).",
								detail="The URI (#local.uri#) for `#local.beanName#`  conflicts with the existing URI definition of `#local.endpoints[local.metaInfo.uriRegex].beanName#`",
								errorcode="taffy.resources.DuplicateUriPattern"
							);
						}

						throwExceptionIfURIDoesntBeginWithForwardSlash(local.uri, local.beanName);

						local.endpoints[local.metaInfo.uriRegex] = { beanName = local.cachedBeanName, tokens = local.metaInfo.tokens, methods = {}, srcURI = local.uri };
						if (structKeyExists(local.cfcMetadata, "functions")) {
							for (local.f in local.cfcMetadata.functions) {
								if (local.f.name == "get" || local.f.name == "post" || local.f.name == "put" || local.f.name == "patch" || local.f.name == "delete" || local.f.name == "head" || local.f.name == "options") {
									local.endpoints[local.metaInfo.uriRegex].methods[local.f.name] = local.f.name;

								// also support future/misc verbs via metadata
								} else if (structKeyExists(local.f, "taffy:verb")) {
									local.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy:verb"]] = local.f.name;
								} else if (structKeyExists(local.f, "taffy_verb")) {
									local.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy_verb"]] = local.f.name;
								}

								// cache any extra function metadata for use in onTaffyRequest
								local.extraMetadata = duplicate(local.f);
								structDelete(local.extraMetadata, "name");
								structDelete(local.extraMetadata, "parameters");
								structDelete(local.extraMetadata, "hint");
								param name="local.endpoints['#local.metaInfo.uriRegex#'].metadata" default={};
								if (!structIsEmpty(local.extraMetadata)) {
									local.endpoints[local.metaInfo.uriRegex].metadata[local.f.name] = local.extraMetadata;
								} else {
									local.endpoints[local.metaInfo.uriRegex].metadata[local.f.name] = {};
								}
							}
						}
					} catch (any cfcatch) {
						// skip cfc's with errors, but save info about them for display in the dashboard
						local.err = {};
						local.err.resource = local.beanName;
						local.err.exception = cfcatch;
						arrayAppend(arguments.taffyRef.status.skippedResources, local.err);
					}
				}
			}
		}
		return local.endpoints;
	}

	private string function getBeanListFromExternalFactory(required bf) output="false" {
		var local = {};
		var beanFactoryMeta = getMetadata(arguments.bf);
		if (lcase(left(beanFactoryMeta.name, 10)) == "coldspring") {
			return getBeanListFromColdSpring(arguments.bf);
		} else if (beanFactoryMeta.name contains "ioc") {
			// this isn't a perfect test (contains "ioc") but it's all we can do for now...
			local.beanInfo = arguments.bf.getBeanInfo().beanInfo;
			local.beanList = "";
			for (local.beanName in local.beanInfo) {
				if (
					structKeyExists(local.beanInfo[local.beanName], "name")
					&& local.beanName != local.beanInfo[local.beanName].name
					&& isInstanceOf(arguments.bf.getBean(local.beanName), "taffy.core.resource")
				) {
					local.beanList = listAppend(local.beanList, local.beanName);
				}
			}
			return local.beanList;
		}
		return "";
	}

	private string function getBeanListFromColdSpring(required bf) output="false" {
		var local = {};
		local.beans = arguments.bf.getBeanDefinitionList();
		local.beanList = "";
		for (local.beanName in local.beans) {
			/*
				Can't call instanceOf() method on beans generated by factories; there is no
				class property on factory-generated beans, and it throws an error in ColdSpring 1.2.
				Temporary patch is to skip those beans, but we'd really either want to examine the
				return type metadata on the factory method or find some other way to determine if
				this is a Taffy bean.
			*/
			if (local.beans[local.beanName].getBeanClass() != "") {
				if (local.beans[local.beanName].instanceOf("taffy.core.resource")) {
					local.beanList = listAppend(local.beanList, local.beanName);
				}
			}
		}
		return local.beanList;
	}

	private function inspectMimeTypes(required string customClassDotPath, required factory) output="false" hint="dot-notation path of representation class" {
		if (arguments.factory.containsBean(arguments.customClassDotPath)) {
			return _recurse_inspectMimeTypes(getMetadata(arguments.factory.getBean(arguments.customClassDotPath)));
		} else {
			return _recurse_inspectMimeTypes(getComponentMetadata(arguments.customClassDotPath));
		}
	}

	private function _recurse_inspectMimeTypes(required struct objMetaData, struct data = {}) output="false" {
		var local = {};
		local.ext = "";
		param name="arguments.data.mimeTypes" default={};
		param name="arguments.data.mimeExtensions" default={};
		param name="arguments.data.defaultMime" default="";
		// recurse into parents first so that child defaults override parent defaults
		if (structKeyExists(arguments.objMetaData, "extends")) {
			arguments.data = _recurse_inspectMimeTypes(arguments.objMetaData.extends, arguments.data);
		}
		// then handle child settings
		if (structKeyExists(arguments.objMetaData, "functions") && isArray(arguments.objMetaData.functions)) {
			local.funcs = arguments.objMetaData.functions;
			for (local.f = 1; local.f <= arrayLen(local.funcs); local.f++) {
				// for every function whose name starts with "getAs" *and* has a taffy_mime metadata attribute, register the mime type
				local.mime = "";
				if (structKeyExists(local.funcs[local.f], "taffy_mime")) {
					local.mime = local.funcs[local.f].taffy_mime;
				} else if (structKeyExists(local.funcs[local.f], "taffy:mime")) {
					local.mime = local.funcs[local.f]["taffy:mime"];
				}
				if (ucase(left(local.funcs[local.f].name, 5)) == "GETAS" && len(local.mime)) {
					local.ext = lcase(right(local.funcs[local.f].name, len(local.funcs[local.f].name) - 5));
					local.mime = lcase(local.mime);
					for (local.thisMime in listToArray(local.mime, ",;")) {
						param name="arguments.data.mimeExtensions['#local.ext#']" default=local.thisMime;
						arguments.data.mimeTypes[local.thisMime] = local.ext;
					}
					// check for taffy_default metadata to set the current mime as the default
					if (structKeyExists(local.funcs[local.f], "taffy_default") && local.funcs[local.f].taffy_default) {
						arguments.data.defaultMime = local.ext;
					} else if (structKeyExists(local.funcs[local.f], "taffy:default") && local.funcs[local.f]["taffy:default"] == true) {
						arguments.data.defaultMime = local.ext;
					}
				}
			}
		}
		return arguments.data;
	}

	private boolean function mimeSupported(required string mimeExt) output="false" {
		if (structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)) {
			return true;
		}
		if (structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)) {
			return true;
		}
		return false;
	}

	private function getReturnMimeAsHeader(required string mimeExt) output="false" {
		if (structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)) {
			return application._taffy.settings.mimeExtensions[arguments.mimeExt];
		}
		if (structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)) {
			return arguments.mimeExt;
		}
	}

	private function getReturnMimeAsExt(required string mimeExt) output="false" {
		if (structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)) {
			return arguments.mimeExt;
		}
		if (structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)) {
			return application._taffy.settings.mimeTypes[arguments.mimeExt];
		}
	}

	private boolean function isUnhandledPathRequest(targetPath) {
		return REFindNoCase("^(" & application._taffy.settings.unhandledPathsRegex & ")", arguments.targetPath);
	}

	private function reFindNoSuck(required string pattern, required string data, startPos = 1) output="false" hint="I wrote this wrapper for reFindNoCase because the way it returns matches is god awful." {
		var local = {};
		local.awesome = [];
		local.sucky = refindNoCase(arguments.pattern, arguments.data, arguments.startPos, true);
		if (!isArray(local.sucky.len) || arrayLen(local.sucky.len) == 0) {
			return [];
		} // handle no match at all
		for (local.i = 1; local.i <= arrayLen(local.sucky.len); local.i++) {
			// if there's a match with pos 0 & length 0, that means the mime type was not specified
			if (local.sucky.len[local.i] > 0 && local.sucky.pos[local.i] > 0) {
				// don't include the group that matches the entire pattern
				local.matchBody = mid(arguments.data, local.sucky.pos[local.i], local.sucky.len[local.i]);
				if (local.matchBody != arguments.data) {
					arrayAppend(local.awesome, local.matchBody);
				}
			}
		}
		return local.awesome;
	}

	// helper methods: stuff used in Application.cfc
	private function getBeanFactory() output="false" {
		return application._taffy.factory;
	}

	private function getExternalBeanFactory() output="false" {
		return application._taffy.externalBeanFactory;
	}

	private function newRepresentation() output="false" hint="private as of 3.0" {
		var repClass = application._taffy.settings.serializer;
		if (application._taffy.factory.containsBean(repClass)) {
			return application._taffy.factory.getBean(repClass);
		} else {
			return createObject("component", repClass);
		}
	}

	public function noData() output="false" {
		return newRepresentation().noData();
	}

	public function noContent() output="false" {
		return newRepresentation().noContent();
	}

	public function representationOf(required data) output="false" {
		return newRepresentation().setData(arguments.data);
	}

	public function rep(required data) output="false" hint="alias for representationOf" {
		return representationOf(arguments.data);
	}

	private struct function getGlobalHeaders() output="false" {
		return application._taffy.settings.globalHeaders;
	}

	public string function getPath() output="false" hint="This method returns just the URI portion of the URL, and makes it easier to port Taffy to other platforms by subclassing this method to match the way the platform works. The default behavior is tested and works on Adobe ColdFusion 9.0.1." {
		if (cgi.path_info == cgi.script_name) {
			// WTF! I've only seen this on Win+IIS, seems fine on OSX+Apache...
			return "";
		}
		return cgi.path_info;
	}

	public void function addHeaders(required struct headers) output="false" {
		var h = "";
		if (!structIsEmpty(arguments.headers)) {
			for (h in arguments.headers) {
				cfheader(name=h, value=arguments.headers[h]);
			}
		}
	}

	public struct function getBasicAuthCredentials() output="false" {
		var local = {};
		local.credentials = {};
		local.credentials.username = "";
		local.credentials.password = "";
		try {
			local.encodedCredentials = ListLast(GetPageContext().getRequest().getHeader("Authorization"), " ");
			local.decodedCredentials = toString(toBinary(local.EncodedCredentials), "iso-8859-1");
			local.credentials.username = listFirst(local.decodedCredentials, ":");
			local.credentials.password = listRest(local.decodedCredentials, ":");
		} catch (any e) {
		}
		return local.credentials;
	}

	function getHostname() {
		// unceremoniously stolen from FW/1
		return createObject("java", "java.net.InetAddress").getLocalHost().getHostName();
	}

	function getHintsFromMetaData(required struct metadata) output="false" {
		var result = {};
		var func = "";
		var f = 0;
		var g = 0;
		var foundFunc = false;
		result.functions = [];

		// don't recurse if we've reached the base component
		if (structKeyExists(metadata, "extends") && metadata.extends.fullname != "taffy.core.resource") {
			result = getHintsFromMetaData(metadata.extends);
		}

		// component attributes
		if (structKeyExists(arguments.metadata, "hint")) {
			// intentionally overwrite hint from any parent cfc's
			result.hint = arguments.metadata.hint;
		}

		// get uri
		if (structKeyExists(arguments.metadata, "taffy_uri")) {
			result.uri = arguments.metadata.taffy_uri;
		}
		if (structKeyExists(arguments.metadata, "taffy:uri")) {
			result.uri = arguments.metadata["taffy:uri"];
		}

		// if there aren't any functions here to grab, return what we already have
		if (!structKeyExists(metadata, "functions") || !isArray(metadata.functions) || !arrayLen(metadata.functions)) {
			return result;
		}

		for (f = 1; f <= arrayLen(metadata.functions); f++) {
			func = metadata.functions[f];
			// ignore hidden methods, if access is not set, assume public
			if (!structKeyExists(func, "access") || (func.access != "private" && func.access != "package")) {
				// check to see if this function is already in the list. If so, overwrite, otherwise append
				foundFunc = false;
				for (g = 1; g <= arrayLen(result.functions); g++) {
					if (result.functions[g].NAME == func.NAME) {
						result.functions[g] = func;
						foundFunc = true;
						break;
					}
				}
				if (!foundFunc) {
					arrayAppend(result.functions, func);
				}
			}
		}

		return result;
	}

	function addTaffyHeader(required string name, required string value) {
		if (application._taffy.settings.exposeTaffyHeaders) {
			cfheader(name=arguments.name, value=arguments.value);
		}
	}

}
