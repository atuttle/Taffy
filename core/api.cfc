<cfcomponent hint="Base class for taffy REST application's Application.cfc">

	<!--- this method is meant to be (optionally) overrided in your application.cfc --->
	<cffunction name="getEnvironment" output="false" hint="override this function to define the current API environment"><cfreturn "" /></cffunction>

	<!---
		onTaffyRequest gives you the opportunity to inspect the request before it is sent to the service.
		If you override this function, you MUST either return TRUE or a representation object
		(eg either taffy.core.nativeJsonSerializer or your default representation class)
	--->
	<cffunction name="onTaffyRequest" output="false">
		<cfargument name="verb" />
		<cfargument name="cfc" />
		<cfargument name="requestArguments" />
		<cfargument name="mimeExt" />
		<cfargument name="headers" />
		<cfargument name="methodMetadata" />
		<cfargument name="matchedURI" />
		<cfreturn true />
	</cffunction>

	<!---
		onTaffyRequestEnd gives you the opportunity to access the request after it has been processed by the service.
		If you override this function, you MUST either return TRUE or a representation object
		(eg either taffy.core.nativeJsonSerializer or your default representation class)
	--->
	<cffunction name="onTaffyRequestEnd" output="false">
		<cfargument name="verb" />
		<cfargument name="cfc" />
		<cfargument name="requestArguments" />
		<cfargument name="mimeExt" />
		<cfargument name="headers" />
		<cfargument name="methodMetadata" />
		<cfargument name="matchedURI" />
		<cfargument name="parsedResponse" />
		<cfargument name="originalResponse" />
		<cfargument name="statusCode" />
		<cfreturn true />
	</cffunction>

	<!--- override these functions to implement caching hooks --->
	<cffunction name="validCacheExists" output="false">
		<cfargument name="cacheKey" />
		<cfreturn false />
	</cffunction>
	<cffunction name="setCachedResponse" output="false">
		<cfargument name="cacheKey" />
		<cfargument name="data" />
	</cffunction>
	<cffunction name="getCachedResponse" output="false">
		<cfargument name="cacheKey" />
	</cffunction>
	<cffunction name="getCacheKey" output="false">
		<cfargument name="cfc" />
		<cfargument name="requestArguments" />
		<cfargument name="matchedURI" />

		<cfreturn arguments.matchedURI & "_" & arguments.requestArguments.hashCode() />
	</cffunction>

	<!--- Your Application.cfc should override this method AND call super.onApplicationStart() --->
	<cffunction name="onApplicationStart">
		<cfset var before = getTickCount() />
		<cfset var after = 0 />
		<cfset setupFramework() />
		<cfset after = getTickCount() />
		<cfheader name="X-TIME-TO-RELOAD" value="#(after-before)#" />
		<cfreturn true />
	</cffunction>

	<!--- Your Application.cfc should override this method AND call super.onRequestStart(targetpath) --->
	<cffunction name="onRequestStart">
		<cfargument name="targetPath" default="" />
		<cfset var local = structNew() />
		<cfset request.unhandled = false />
		<cfset local.reloadedInThisRequest = false />
		<cfset request.taffyReloaded = false />
		<!--- this will probably happen if taffy is sharing an app name with an existing application so that you can use its application context --->
		<cfif not structKeyExists(application, "_taffy")>
			<cfset onApplicationStart() />
			<cfset local.reloadedInThisRequest = true />
		</cfif>
		<!--- allow reloading --->
		<cfif
			(
				structKeyExists(url, application._taffy.settings.reloadKey)
				AND
				url[application._taffy.settings.reloadKey] eq application._taffy.settings.reloadPassword
			)
			OR
			(
				application._taffy.settings.reloadOnEveryRequest eq true
			)>
			<cfif !local.reloadedInThisRequest and !isUnhandledPathRequest(arguments.targetPath)><!--- prevent double reloads --->
				<cfset onApplicationStart() />
			</cfif>
		</cfif>
		<cfif !isUnhandledPathRequest(arguments.targetPath)>
			<!--- if browsing to root of api, show dashboard --->
			<cfset local.path = replaceNoCase(cgi.path_info, cgi.script_name, "") />
			<cfif
				NOT structKeyExists(url,application._taffy.settings.endpointURLParam)
				AND NOT structKeyExists(form,application._taffy.settings.endpointURLParam)
				AND len(local.path) lte 1
				AND listFindNoCase(cgi.script_name, "index.cfm", "/") EQ listLen(cgi.script_name, "/")>
				<cfif NOT application._taffy.settings.disableDashboard>
					<cfif StructKeyExists( URL, "docs" )>
						<cfinclude template="#application._taffy.settings.docsPath#" />
					<cfelse>
						<cfinclude template="../dashboard/dashboard.cfm" />
					</cfif>
					<cfabort />
				<cfelse>
					<cfif len(application._taffy.settings.disabledDashboardRedirect)>
						<cflocation url="#application._taffy.settings.disabledDashboardRedirect#" addtoken="false" />
						<cfabort />
					<cfelseif application._taffy.settings.showDocsWhenDashboardDisabled IS False>
						<cfset throwError(403, "Forbidden") />
					</cfif>
				</cfif>
			</cfif>
		<cfelse>
			<!--- allow pass-thru for selected paths --->
			<cfset structDelete(this, 'onRequest') />
			<cfset structDelete(variables, 'onRequest') />
			<cfset request.unhandled = true />
		</cfif>
		<cfreturn true />
	</cffunction>

	<!--- If you choose to override this function, consider calling super.onError(exception) --->
	<cffunction name="onError">
		<cfargument name="exception" />
		<cfset var data = {} />
		<cfset var root = '' />
		<cfset var logger = '' />
		<cftry>
			<cfif structKeyExists(request, 'unhandled') and request.unhandled eq true>
				<cfreturn super.onError( arguments.exception ) />
			</cfif>

			<cfset logger = createObject("component", application._taffy.settings.exceptionLogAdapter).init(
				application._taffy.settings.exceptionLogAdapterConfig
			) />
			<cfset logger.saveLog(exception) />

			<!--- return 500 no matter what --->
			<cfheader statuscode="500" statustext="Error" />
			<cfcontent reset="true" />

			<cfif structKeyExists(exception, "rootCause")>
				<cfset root = exception.rootCause />
			<cfelse>
				<cfset root = exception />
			</cfif>

			<cfif structKeyExists(root, "TagContext")>
				<cfset data.stacktrace = root.tagContext />
			</cfif>

			<cfif application._taffy.settings.returnExceptionsAsJson eq true>
				<!--- try to find the relevant details --->
				<cfif structKeyExists(root, "message")>
					<cfset data.error = root.message />
				</cfif>
				<cfif structKeyExists(root, "detail")>
					<cfset data.detail = root.detail />
				</cfif>
				<cfif structKeyExists(root,"tagContext")>
					<cfset data.tagContext = root.tagContext[1].template & " [Line #root.tagContext[1].line#]" />
				</cfif>
				<!--- MAKE IT LOOK GOOD! --->
				<cfsetting enablecfoutputonly="true" showdebugoutput="false" />
				<cfcontent type="application/json; charset=utf-8" />
				<cfoutput>#serializeJson(data)#</cfoutput>
			</cfif>
			<cfcatch>
				<cfcontent reset="true" type="text/plain; charset=utf-8" />
				<cfheader statuscode="500" statustext="Error" />
				<cfoutput>An unhandled exception occurred: <cfif isStruct(root) and structKeyExists(root,"message")>#root.message#<cfelse>#root#</cfif> <cfif isStruct(root) and structKeyExists(root,"detail")>-- #root.detail#</cfif></cfoutput>
				<cfdump var="#cfcatch#" format="text" label="ERROR WHEN LOGGING EXCEPTION" />
				<cfdump var="#exception#" format="text" label="ORIGINAL EXCEPTION" />
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<cffunction name="onRequest" output="true" returntype="boolean">
		<cfargument name="targetPage" type="string" required="true" />

		<cfscript>
			var _taffyRequest = 0;
			var _taffyResponse = { headers: {} };

			try {
				// will output and abort if applicable
				handleDashboard();

				request._taffyRequest = _taffyRequest; //copied by ref
				metricsHeader("X-TIME-IN-INITIALIZE", function(){
					// initialization
					_taffyRequest = initializeRequest();
					structAppend(_taffyResponse.headers, application._taffy.settings.globalHeaders);
				});

				// parse the request
				metricsHeader("X-TIME-IN-PARSE", function(){
					var parsed = parseRequest();
					structAppend(_taffyRequest, parsed);
				});

				// CORS headers
				metricsHeader("X-TIME-IN-CORS", function(){
					var corsHeaders = handleCORS(_taffyRequest);
					structAppend(_taffyResponse.headers, corsHeaders);
				});

				// handle requested response mime not available
				detectUnsupportedResponseFormat(_taffyRequest);

				// service the request
				serviceRequest(_taffyRequest);
				_taffyResponse.fromService = _taffyRequest.result;

				// output result
				respond(_taffyRequest, _taffyResponse);

				return true;
			}catch(any e){
				//output any headers we've collected before bubbling up to the exception handler
				addHeaders(_taffyResponse.headers);
				rethrow;
			}
		</cfscript>
	</cffunction>

	<cffunction name="metricsHeader">
		<cfargument name="headerName" required="true" type="string" />
		<cfargument name="callback" required="true" />
		<cfscript>
			var startTime = getTickCount();
			callback();
			var stopTime = getTickCount();
			var duration = stopTime - startTime;
		</cfscript>
		<cfheader name="#arguments.headerName#" value="#duration#" />
	</cffunction>

	<cffunction name="initializeRequest">
		<!--- enable/disable debug output per settings --->
		<cfif not structKeyExists(url, application._taffy.settings.debugKey)>
			<cfsetting showdebugoutput="false" />
		</cfif>

		<cfset var _taffyRequest = {} />
		<cfreturn _taffyRequest />
	</cffunction>

	<cffunction name="handleDashboard" access="private">
		<cfif
			NOT structKeyExists(url,application._taffy.settings.endpointURLParam)
			AND NOT structKeyExists(form,application._taffy.settings.endpointURLParam)
			AND len(cgi.path_info) lte 1
			AND listFindNoCase(cgi.script_name, "index.cfm", "/") EQ listLen(cgi.script_name, "/")>
			<cfif NOT application._taffy.settings.disableDashboard>
				<cfif StructKeyExists( URL, "docs" )>
					<cfinclude template="#application._taffy.settings.docsPath#" />
				<cfelse>
					<cfinclude template="../dashboard/dashboard.cfm" />
				</cfif>
				<cfabort />
			<cfelse>
				<cfif len(application._taffy.settings.disabledDashboardRedirect)>
					<cflocation url="#application._taffy.settings.disabledDashboardRedirect#" addtoken="false" />
					<cfabort />
				<cfelseif application._taffy.settings.showDocsWhenDashboardDisabled>
					<cfinclude template="#application._taffy.settings.docsPath#" />
					<cfabort />
				<cfelse>
					<cfset throwError(403, "Forbidden") />
				</cfif>
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="handleCORS">
		<cfargument name="_taffyRequest" required="true" />
		<cfset headers = {} />
		<cfset var allowVerbs = uCase(structKeyList(_taffyRequest.matchDetails.methods)) />
		<cfif (application._taffy.settings.allowCrossDomain eq true or len(application._taffy.settings.allowCrossDomain) gt 0)
				AND listFindNoCase('PUT,PATCH,DELETE,OPTIONS',_taffyRequest.verb)
				AND NOT listFind(allowVerbs,'OPTIONS')>
			<cfset allowVerbs = listAppend(allowVerbs,'OPTIONS') />
		</cfif>
		<cfif structKeyExists(_taffyRequest.headers, "origin") AND (application._taffy.settings.allowCrossDomain eq true or len(application._taffy.settings.allowCrossDomain) gt 0)>
			<cfif application._taffy.settings.allowCrossDomain eq true>
				<cfset headers['Access-Control-Allow-Origin'] = '*' />
			<cfelse>
				<!---
					The Access-Control-Allow-Origin header can only have 1 value so we check to see if the Origin header is
					in the list of origins specified in the config setting and parrot back the Origin header if so.
					We also need to add the Access-Control-Allow-Credentials header and set it to true for those type requests
				--->
				<cfset var domains = listToArray( application._taffy.settings.allowCrossDomain, ', ;' )>
				<cfif structKeyExists(_taffyRequest.headers, "origin")>
					<cfloop from="1" to="#arrayLen( domains )#" index="local.i">
						<cfif lcase( rereplace( _taffyRequest.headers.origin, "(http|https):\/\/", "", "all" ) ) EQ lcase( rereplace( domains[ local.i ], "(http|https):\/\/", "", "all" ) ) >
							<cfset headers['Access-Control-Allow-Origin'] = _taffyRequest.headers.origin />
							<cfset headers['Access-Control-Allow-Credentials'] = 'true' />
							<cfbreak>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
			<cfheader name="Access-Control-Allow-Methods" value="#allowVerbs#" />
			<!--- Why do we parrot back these headers? See: https://github.com/atuttle/Taffy/issues/144 --->
			<cfif not structKeyExists(_taffyRequest.headers, "Access-Control-Request-Headers")>
				<cfset headers['Access-Control-Allow-Headers'] = 'Origin, Authorization, X-CSRF-Token, X-Requested-With, Content-Type, X-HTTP-Method-Override, Accept, Referrer, User-Agent' />
			<cfelse>
				<!--- parrot back all of the request headers to allow the request to continue (can we improve on this?) --->
				<cfset var allowedHeaders = {} />
				<cfset var h = '' />
				<cfloop list="Origin,Authorization,X-CSRF-Token,X-Requested-With,Content-Type,X-HTTP-Method-Override,Accept,Referrer,User-Agent" index="h">
					<cfset allowedHeaders[h] = 1 />
				</cfloop>
				<cfset var requestedHeaders = _taffyRequest.headers['Access-Control-Request-Headers'] />
				<cfset var i = 0 />
				<cfloop list="#requestedHeaders#" index="i">
					<cfset allowedHeaders[ i ] = 1 />
				</cfloop>
				<cfset headers['Access-Control-Allow-Headers'] = structKeyList(allowedHeaders) />
			</cfif>
		</cfif>

		<cfif NOT listFind(allowVerbs,_taffyRequest.verb)>
			<!--- if the verb is not implemented, refuse the request --->
			<cfset headers['ALLOW'] = allowVerbs />
			<!--- TODO: if we throw we won't have access to the headers variable :o( --->
			<cfset throwError(405, "Method Not Allowed") />
		</cfif>

		<cfreturn headers />
	</cffunction>

	<cffunction name="detectUnsupportedResponseFormat">
		<cfargument name="_taffyRequest" required="true" />
		<cfif not mimeSupported(_taffyRequest.returnMimeExt)>
			<cfset throwError(400, "Requested format not available (#_taffyRequest.returnMimeExt#)") />
		</cfif>
	</cffunction>

	<cffunction name="checkCache">
		<cfargument name="_taffyRequest" required="true" />
		<cfscript>
			var cachedResponse = "not-found-in-cache";
			metricsHeader("X-TIME-IN-CACHE-GET", function(){
				var cacheKey = getCacheKey(
					_taffyRequest.matchDetails.beanName
					,_taffyRequest.requestArguments
					,_taffyRequest.matchDetails.srcUri
				);
				if ( ucase(_taffyRequest.verb) == "GET" and validCacheExists(cacheKey) ){
					cachedResponse = getCachedResponse(cacheKey);
				}
			});
			if ( cachedResponse == "not-found-in-cache" ){
				return;
			}
			return cachedResponse;
		</cfscript>
	</cffunction>

	<cffunction name="upsertCache">
		<cfargument name="_taffyRequest" required="true" />
		<cfscript>
			metricsHeader("X-TIME-IN-CACHE-SET", function(){
				var cacheKey = getCacheKey(
					_taffyRequest.matchDetails.beanName
					,_taffyRequest.requestArguments
					,_taffyRequest.matchDetails.srcUri
				);
				//TODO: update the cache
				setCachedResponse(cacheKey, _taffyRequest.result);
			});
		</cfscript>
	</cffunction>

	<cffunction name="serviceRequest">
		<cfargument name="_taffyRequest" required="true" />
		<cfscript>
			metricsHeader("X-TIME-IN-ONTAFFYREQUEST", function(){
				_taffyRequest.continue = onTaffyRequest(
					_taffyRequest.verb
					,_taffyRequest.matchDetails.beanName
					,_taffyRequest.requestArguments
					,_taffyRequest.returnMimeExt
					,_taffyRequest.headers
					,_taffyRequest.methodMetadata
					,_taffyRequest.matchDetails.srcUri
				);

				if (!structKeyExists(_taffyRequest, "continue")){
					throw (
						message: "Error in your onTaffyRequest method",
						detail: "Your onTaffyRequest method returned no value. Expected: Return TRUE or call noData()/rep().",
						errorcode: "400"
					);
				}
			});

			if (!mimeSupported(_taffyRequest.returnMimeExt)){
				throwError(400, "Requested format not available (#_taffyRequest.returnMimeExt#)");
			}

			var interrupt = isObject(_taffyRequest.continue);
			var simulateKeyMatch = structKeyExists(_taffyRequest.requestArguments, application._taffy.settings.simulateKey);
			var simulatePasswordMatch = simulateKeyMatch && _taffyRequest.requestArguments[application._taffy.settings.simulateKey] == application._taffy.settings.simulatePassword;
			var isSimulatedRequest = simulateKeyMatch && simulatePasswordMatch;

			// request has been interrupted by developer; return custom response
			if (interrupt){
				_taffyRequest.result = duplicate(_taffyRequest.continue);
				structDelete(_taffyRequest, "continue");
				return;
			}

			if ( isSimulatedRequest ){
				// is there a simulated response?
				var sampler = 'sample#_taffyRequest.method#Response';
				if (structKeyExists(_taffyRequest.matchDetails.metadata, sampler)){
					// get simulated response
					var resource = application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName);
					var getSample = resource[sampler];
					_taffyRequest.result = rep(getSample());
				}else {
					// no method for simulated response, so return 400
					_taffyRequest.result = noData().withStatus(400, "No Sample Response Available");
				}
				return;
			}

			var cachedResponse = checkCache(_taffyRequest);
			//void response = not cached
			if ( isDefined("cachedResponse") ){
				_taffyRequest.result = cachedResponse;
				return;
			}

			// ask resource to handle the request
			metricsHeader("X-TIME-IN-RESOURCE", function(){
				// returns a representation object
				var resource = application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName);
				var handler = resource[_taffyRequest.method];
				_taffyRequest.result = handler( argumentCollection: _taffyRequest.requestArguments );

				if (!isDefined("_taffyRequest.result")){
					throw(
						message: "Resource did not return a value",
						detail: "The resource is expected to return a call to rep()/representationOf() or noData(). It appears there was no return at all.",
						errorcode: "taffy.resources.ResourceReturnsNothing"
					);
				}

				// Allow resources to return bare data and automatically wrap with a rep() as needed.
				if (!isInstanceOf(_taffyRequest.result, "taffy.core.baseSerializer")){
					_taffyRequest.result = rep(_taffyRequest.result);
				}
			});

			//update the cache if applicable
			if (ucase(_taffyRequest.verb) == "GET"){
				upsertCache(_taffyRequest);
			}

			return;
		</cfscript>
	</cffunction>

	<cffunction name="respond">
		<cfargument name="_taffyRequest" required="true" />
		<cfargument name="_taffyResponse" required="true" />
		<cfscript>
			if (structKeyExists(_taffyRequest,'result')){
				arguments._taffyResponse.statusArgs = {
					statusCode: arguments._taffyRequest.result.getStatus(),
					statusText: arguments._taffyRequest.result.getStatusText()
				};
				structAppend(arguments._taffyResponse.headers, arguments._taffyRequest.result.getHeaders());
			}else{
				//cross domain OPTIONS request (dummy response)
				_taffyResponse.statusArgs = {
					statusCode: 200,
					statusText: 'OK'
				};
			}

			//inspecting/filtering response headers to determine if Access-Control-Expose-Headers is necessary; including it in the response if it is
			if (application._taffy.settings.exposeHeaders){
				var exposeHeaderList = structKeyList(_taffyResponse.headers);
				var exposeHeaderValue = "";
				if (
					application._taffy.settings.useEtags
					&& _taffyRequest.verb == "GET"
					&& _taffyRequest.result.getType() eq "textual"
				){
					exposeHeaderList = listAppend(exposeHeaderList, "Etag");
				}
				for (var exposeHeader in exposeHeaderList){
					// filter out default simple response headers: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers
					if (!listFindNoCase("Cache-Control,Content-Language,Content-Type,Expires,Last-Modified,Pragma", exposeHeader)){
						exposeHeaderValue = listAppend(exposeHeaderValue, exposeHeader);
					}
				}
				if (listLen(local.exposeHeaderValue) gt 0){
					_taffyResponse.headers['Access-Control-Expose-Headers'] = exposeHeaderValue;
				}
			}

			resetBuffer(_taffyRequest);

			// output headers
			cfheader(
				statusCode: _taffyResponse.statusArgs.statusCode,
				statusText: _taffyResponse.statusArgs.statusText
			);
			addHeaders(_taffyResponse.headers);

			// output body (text/file/etc)
			var resultSerialized = '';
			if (structKeyExists(_taffyRequest,'result')){
				_taffyResponse.resultType = _taffyRequest.result.getType();

				if (_taffyResponse.resultType == "textual"){
					// serialize the representation's data into the requested mime type
					metricsHeader("X-TIME-IN-SERIALIZE", function(){
						cfinvoke(
							component: _taffyRequest.result,
							method: "getAs#_taffyRequest.returnMimeExt#",
							returnVariable: "_taffyResponse.resultSerialized"
						);
					});

					// apply jsonp wrapper if requested
					if (structKeyExists(_taffyRequest, "jsonpCallback")){
						_taffyResponse.resultSerialized = _taffyRequest.jsonpCallback & "(" & _taffyResponse.resultSerialized & ");";
					}

					// don't return data if etags are enabled and the data hasn't changed
					if (application._taffy.settings.useEtags && _taffyRequest.verb == "GET"){
						// etag values are quoted per: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
						if (structKeyExists(server, "lucee")){
							// hashCode() will not work for lucee, see issue #354
							_taffyResponse.serverEtag = '"' & hash(_taffyResponse.resultSerialized) & '"';
						}else{
							_taffyResponse.serverEtag = '"' & _taffyRequest.result.getData().hashCode() & '"';
						}
						if (structKeyExists(_taffyRequest.headers, "If-None-Match")){
							_taffyRequest.clientEtag = _taffyRequest.headers['If-None-Match'];

							if (len(_taffyRequest.clientEtag) > 0 && _taffyRequest.clientEtag == _taffyResponse.serverEtag){
								cfheader(statuscode: 304, statustext: "Not Modified");
								cfcontent(
									reset: true,
									type: "#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8"
								);
								return true;
							}else{
								cfheader(name="Etag", value="#_taffyResponse.serverEtag#");
							}
						}else{
							cfheader(name="Etag", value="#_taffyResponse.serverEtag#");
						}
					}

					cfcontent(
						reset="true",
						type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8"
					);
					if (_taffyResponse.resultSerialized neq ('"' & '"')){
						resultSerialized = _taffyResponse.resultSerialized;
					}

					// debug output is only ever enabled for text responses (so it doesn't corrupt files)
					var debug = false;
					if (structKeyExists(url, application._taffy.settings.debugKey)){
						debug = true;
					}

				}

				if (_taffyResponse.resultType eq "filename"){
					cfcontent(
						reset="true",
						file="#_taffyRequest.result.getFileName()#",
						type="#_taffyRequest.result.getFileMime()#",
						deletefile="#_taffyRequest.result.getDeleteFile()#"
					);
				}

				if (_taffyResponse.resultType eq "filedata"){
					cfcontent(
						reset="true",
						variable="#_taffyRequest.result.getFileData()#",
						type="#_taffyRequest.result.getFileMime()#"
					);
				}

				if (_taffyResponse.resultType eq "imagedata"){
					cfcontent(
						reset="true",
						variable="#_taffyRequest.result.getImageData()#",
						type="#_taffyRequest.result.getFileMime()#"
					);
				}
			}

			if (structKeyExists( _taffyResponse, "resultSerialized" )){
				resultSerialized = _taffyResponse.resultSerialized;
			}

			var result = {};
			if (structKeyExists( _taffyRequest, "result" )){
				result = _taffyRequest.result.getData();
			}

			// ...after the service has finished...
			metricsHeader("X-TIME-IN-ONTAFFYREQUESTEND", function(){
				onTaffyRequestEnd(
					_taffyRequest.verb
					,_taffyRequest.matchDetails.beanName
					,_taffyRequest.requestArguments
					,_taffyRequest.returnMimeExt
					,_taffyRequest.headers
					,_taffyRequest.methodMetadata
					,_taffyRequest.matchDetails.srcUri
					,resultSerialized
					,result
					,_taffyResponse.statusArgs.statusCode
					);
			});

			if (len(trim(resultSerialized))){
				writeOutput("#resultSerialized#");
			}

			if (debug){
				writeOutput('<h3>Request Details:</h3><cfdump var="#_taffyRequest#">');
			}
		</cfscript>
	</cffunction>

	<cffunction name="resetBuffer">
		<cfargument name="_taffyRequest" required="true" />
		<cfsetting enablecfoutputonly="true" />
		<cfcontent reset="true" type="#getReturnMimeAsHeader(arguments._taffyRequest.returnMimeExt)#; charset=utf-8" />
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- internal methods --->
	<cffunction name="setupFramework" access="private" output="false" returntype="void">
		<cfset var local = structNew() />
		<cfparam name="variables.framework" default="#structNew()#" />
		<cfheader name="X-TAFFY-RELOADED" value="true" />
		<cfset request.taffyReloaded = true />
		<cfset local._taffy = structNew() />
		<cfset local._taffy.version = "3.3.0" />
		<cfset local._taffy.endpoints = structNew() />
		<!--- default settings --->
		<cfset local.defaultConfig = structNew() />
		<cfset local.defaultConfig.docs = structNew() />
		<cfset local.defaultConfig.docs.APIName = "Your API Name (variables.framework.docs.APIName)" />
		<cfset local.defaultConfig.docs.APIVersion = "0.0.0 (variables.framework.docs.APIVersion)" />
		<cfset local.defaultConfig.docsPath = "../dashboard/docs.cfm" />
		<cfset local.defaultConfig.defaultMime = "" />
		<cfset local.defaultConfig.debugKey = "debug" />
		<cfset local.defaultConfig.reloadKey = "reload" />
		<cfset local.defaultConfig.reloadPassword = "true" />
		<cfset local.defaultConfig.reloadOnEveryRequest = false />
		<cfset local.defaultConfig.simulateKey = "sampleResponse" />
		<cfset local.defaultConfig.simulatePassword = "true" />
		<cfset local.defaultConfig.endpointURLParam = 'endpoint' />
		<cfset local.defaultConfig.serializer = "taffy.core.nativeJsonSerializer" />
		<cfset local.defaultConfig.deserializer = "taffy.core.nativeJsonDeserializer" />
		<cfset local.defaultConfig.disableDashboard = false />
		<cfset local.defaultConfig.disabledDashboardRedirect = "" />
		<cfset local.defaultConfig.dashboardHeaders = {} />
		<cfset local.defaultConfig.showDocsWhenDashboardDisabled = false />
		<cfset local.defaultConfig.unhandledPaths = "/flex2gateway" />
		<cfset local.defaultConfig.allowCrossDomain = false />
		<cfset local.defaultConfig.useEtags = false />
		<cfset local.defaultConfig.exposeHeaders = false />
		<cfset local.defaultConfig.jsonp = false />
		<cfset local.defaultConfig.noDataSends204NoContent = false />
		<cfset local.defaultConfig.globalHeaders = structNew() />
		<cfset local.defaultConfig.mimeTypes = structNew() />
		<cfset local.defaultConfig.returnExceptionsAsJson = true />
		<cfset local.defaultConfig.exceptionLogAdapter = "taffy.bonus.LogToDevNull" />
		<cfset local.defaultConfig.exceptionLogAdapterConfig = StructNew() />
		<cfset local.defaultConfig.csrfToken = structNew() />
		<cfset local.defaultConfig.csrfToken.cookieName = "" />
		<cfset local.defaultConfig.csrfToken.headerName = "" />
		<!--- status --->
		<cfset local._taffy.status = structNew() />
		<cfset local._taffy.status.internalBeanFactoryUsed = false />
		<cfset local._taffy.status.externalBeanFactoryUsed = false />
		<cfset local._taffy.uriMatchOrder = [] />
		<!--- allow setting overrides --->
		<cfset local._taffy.settings = structNew() />
		<cfset structAppend(local._taffy.settings, local.defaultConfig, true) /><!--- initialize to default values --->
		<cfset structAppend(local._taffy.settings, variables.framework, true) /><!--- update with user values --->
		<!--- allow environment-specific config --->
		<cfset local.env = getEnvironment() />
		<cfif len(local.env) gt 0>
			<cfparam name="variables.framework" default="#structNew()#" />
			<cfparam name="variables.framework.environments" default="#structNew()#" />
			<cfif structKeyExists(variables.framework.environments, local.env) and isStruct(variables.framework.environments[local.env])>
				<cfset structAppend(local._taffy.settings, variables.framework.environments[local.env]) />
			</cfif>
		</cfif>
		<!--- bean factory definition --->
		<cfif structKeyExists(variables.framework, "beanFactory")>
			<cfif isSimpleValue(variables.framework.beanFactory) and len(variables.framework.beanFactory) eq 0>
				<!--- if the BF value is "" doing nothing with it --->
			<cfelse>
				<cfset local._taffy.externalBeanFactory = variables.framework.beanFactory />
				<cfset local._taffy.status.externalBeanFactoryUsed = true />
			</cfif>
		</cfif>
		<!--- translate unhandledPaths config to regex for easier matching (This is ripped off from FW/1. Thanks, Sean!) --->
		<cfset local._taffy.settings.unhandledPathsRegex = replaceNoCase(
			REReplace(local._taffy.settings.unhandledPaths, '(\+|\*|\?|\.|\[|\^|\$|\(|\)|\{|\||\\)', '\\\1', 'all' ),
			',', '|', 'all' )
		/>
		<!--- if resources folder exists, use internal bean factory --->
		<cfset local.resourcePath = guessResourcesFullPath() />
		<cfset local.noResources = false />
		<cfif directoryExists(local.resourcePath)>
			<!--- setup internal bean factory --->
			<cfset local._taffy.factory = createObject("component", "taffy.core.factory") />
			<cfif structKeyExists(local._taffy, "externalBeanFactory")>
				<cfset local._taffy.factory.init(local._taffy.externalBeanFactory) />
			<cfelse>
				<cfset local._taffy.factory.init() />
			</cfif>
			<cfset local._taffy.factory.loadBeansFromPath(local.resourcePath, guessResourcesCFCPath(), guessResourcesFullPath(), true, local._taffy) />
			<cfset local._taffy.beanList = local._taffy.factory.getBeanList() />
			<cfset local._taffy.endpoints = cacheBeanMetaData(local._taffy.factory, local._taffy.beanList, local._taffy) />
			<cfset local._taffy.status.internalBeanFactoryUsed = true />
		<cfelseif local._taffy.status.externalBeanFactoryUsed>
			<!--- only using external factory, so create a pointer to it --->
			<cfset local._taffy.factory = local._taffy.externalBeanFactory />
			<!--- since external factory is only factory, check it for taffy resources --->
			<cfset local.beanList = getBeanListFromExternalFactory( local._taffy.externalBeanFactory ) />
			<cfset local._taffy.endpoints = cacheBeanMetaData(local._taffy.externalBeanFactory, local.beanList, local._taffy) />
 		<cfelse>
 			<cfset local.noResources = true />
		</cfif>
		<cfif not local.noResources>
			<!--- sort URIs --->
			<cfset local._taffy.URIMatchOrder = sortURIMatchOrder(local._taffy.endpoints) />
			<!--- automatically introspect mime types from cfc metadata of default representation class --->
			<cfset local.mimetypes = inspectMimeTypes(local._taffy.settings.serializer, local._taffy.factory) />
			<cfset structAppend(local._taffy.settings, local.mimeTypes) />
			<!--- check to make sure a default mime type is set --->
			<cfif local._taffy.settings.defaultMime eq "">
				<cfset throwError(400, "You have not specified a default mime type!") />
			</cfif>
		</cfif>
		<!--- inspect the deserializer to find out what contentTypes are supported --->
		<cfset local._taffy.contentTypes = getSupportedContentTypes(local._taffy.settings.deserializer) />
		<!--- hot-swap! --->
		<cfset application._taffy = local._taffy />
	</cffunction>

	<cffunction name="parseRequest" access="private" output="false" returnType="struct">
		<cfset var requestObj = {} />
		<cfset var tmp = 0 />
		<cfset var local = {} />

		<!--- Check for method tunnelling by clients unable to send PUT/DELETE requests (e.g. Flash Player);
					Actual desired method will be contained in a special header --->
 		<cfset var httpMethodOverride = GetPageContext().getRequest().getHeader("X-HTTP-Method-Override") />

		<cfset requestObj.uri = getPath() />
		<cfif NOT len(requestObj.uri)>
			<cfif structKeyExists(url,application._taffy.settings.endpointURLParam)>
				<cfset requestObj.uri = urlDecode( url[application._taffy.settings.endpointURLParam] ) />

			<cfelseif structKeyExists(form,application._taffy.settings.endpointURLParam)>
				<cfset requestObj.uri = urlDecode( form[application._taffy.settings.endpointURLParam] ) />
			</cfif>
		</cfif>

 		<!--- check for format in the URI --->
 		<cfset requestObj.uriFormat = formatFromURI(requestObj.uri) />

		<!--- attempt to find the cfc for the requested uri --->
		<cfset requestObj.matchingRegex = matchURI(requestObj.uri) />

		<!--- uri doesn't map to any known resources --->
		<cfif not len(requestObj.matchingRegex)>
			<cfset throwError(404, "Not Found") />
		</cfif>

		<!--- get the cfc name and token array for the matching regex --->
		<cfset requestObj.matchDetails = application._taffy.endpoints[requestObj.matchingRegex] />

		<!--- which verb is requested? --->
		<cfset requestObj.verb = cgi.request_method />

		<!--- Should we override the actual method based on method tunnelling? --->
		<cfif isDefined("httpMethodOverride") AND not isNull(httpMethodOverride)>
		    <cfset requestObj.verb = httpMethodOverride />
		</cfif>

		<cfif structKeyExists(application._taffy.endpoints[requestObj.matchingRegex].methods, requestObj.verb)>
			<cfset requestObj.method = application._taffy.endpoints[requestObj.matchingRegex].methods[requestObj.verb] />
		<cfelse>
			<cfset requestObj.method = "" />
		</cfif>

		<cfset requestObj.body = getRequestBody() />
		<cfset requestObj.contentType = cgi.content_type />
		<cfif len(requestObj.body) AND requestObj.body neq "null">
			<cfif findNoCase("multipart/form-data", requestObj.contentType)>
				<!--- do nothing, to support the way railo handles multipart requests (just avoids the error condition below) --->
				<cfset requestObj.queryString = cgi.query_string />
			<cfelse>
				<cfif contentTypeIsSupported(requestObj.contentType)>
					<cfset requestObj.bodyArgs = getDeserialized(requestObj.body, requestObj.contentType) />
					<cfset requestObj.queryString = cgi.query_string />
				<cfelse>
					<cfif isJson(requestObj.body)>
						<cfset throwError(400, "Looks like you're sending JSON data, but you haven't specified a content type. Aborting request.") />
					<cfelse>
						<cfset throwError(400, "You must specify a content-type. Aborting request.") />
					</cfif>
				</cfif>
			</cfif>
		<cfelse>
			<!--- actual query parameters --->
			<cfset requestObj.queryString = cgi.query_string />
		</cfif>

		<!--- grab request headers --->
		<cfset requestObj.headers = getHTTPRequestData().headers />

		<!--- build the argumentCollection to pass to the cfc --->
		<cfset requestObj.requestArguments = buildRequestArguments(
			requestObj.matchingRegex,
			requestObj.matchDetails.tokens,
			requestObj.uri,
			requestObj.queryString,
			requestObj.headers
		) />
		<!--- include any deserialized body params --->
		<cfif structKeyExists(requestObj, "bodyArgs")>
			<cfset structAppend(requestObj.requestArguments, requestObj.bodyArgs) />
		</cfif>
		<!--- also capture form POST data (higher priority that url variables of same name) --->
		<cfset structAppend(requestObj.requestArguments, form) />

		<!--- if JSONP is enabled, capture the requested callback name --->
		<cfif application._taffy.settings.jsonp neq false>
			<cfif structKeyExists(requestObj.requestArguments, application._taffy.settings.jsonp)>
				<!--- variables.framework.jsonp contains the callback parameter name --->
				<cfset requestObj.jsonpCallback = requestObj.requestArguments[application._taffy.settings.jsonp] />
			</cfif>
		</cfif>

		<!--- use requested mime type or the default --->
		<cfset requestObj.returnMimeExt = "" />
		<cfif structKeyExists(requestObj.requestArguments, "_taffy_mime")>
			<cfset requestObj.returnMimeExt = requestObj.requestArguments._taffy_mime />
			<cfif left(requestObj.returnMimeExt, 1) eq ".">
				<cfset requestObj.returnMimeExt = right(requestObj.returnMimeExt, len(requestObj.returnMimeExt)-1) />
			</cfif>
			<cfif requestObj.returnMimeExt eq "*/*">
				<cfset requestObj.returnMimeExt = application._taffy.settings.defaultMime />
			</cfif>
			<cfif not structKeyExists(application._taffy.settings.mimeExtensions, requestObj.returnMimeExt)>
				<cfset throwError(400, "Requested mime type is not supported (#requestObj.returnMimeExt#)") />
			</cfif>
		<cfelseif requestObj.uriFormat neq "">
			<cfset requestObj.returnMimeExt = requestObj.uriFormat />
		<cfelse>
			<!--- run some checks on the default --->
			<cfif application._taffy.settings.defaultMime eq "">
				<cfset throwError(400, "You have not specified a default mime type") />
			<cfelseif not structKeyExists(application._taffy.settings.mimeExtensions, application._taffy.settings.defaultMime)>
				<cfset throwError(400, "Your default mime type (#application._taffy.settings.defaultMime#) is not implemented") />
			</cfif>
			<cfset requestObj.returnMimeExt = application._taffy.settings.defaultMime />
		</cfif>
		<cfset structDelete(requestObj.requestArguments, "_taffy_mime") />
		<!--- get the method metadata (if any) for onTaffyRequest --->
		<cfif requestObj.method neq "">
			<cfset requestObj.methodMetadata = application._taffy.endpoints[requestObj.matchingRegex].metadata[requestObj.method] />
		<cfelse>
			<!--- method will be "" when un-implemented method is requested (e.g. OPTIONS) --->
			<cfset requestObj.methodMetadata = StructNew() />
		</cfif>
		<cfreturn requestObj />
	</cffunction>

	<cffunction name="formatFromURI" access="private" output="false">
		<cfargument name="uri" />
		<cfset var local = structNew() />
		<cfloop collection="#application._taffy.settings.mimeExtensions#" item="local.mime">
			<cfif right(arguments.uri, len(local.mime)+1) eq "." & local.mime>
				<cfreturn local.mime />
			</cfif>
		</cfloop>
		<cfreturn "" />
	</cffunction>

	<cffunction name="convertURItoRegex" access="private" output="false">
		<cfargument name="uri" type="string" required="true" hint="wants the uri mapping defined by the cfc endpoint" />
		<cfset var local = StructNew() />

		<cfset local.uriChunks = listToArray(arguments.uri, '/') />
		<cfset local.returnData = StructNew() />
		<cfset local.returnData.tokens = ArrayNew(1) />
		<cfset local.uriMatcher = "" />

		<cfset local.regexes.segment = "([^\/]+)" /> <!--- anything but a slash --->
		<cfset local.regexes.segmentWithOptFormat = "(?:(?:([^\/\.]+)(?:\.)([a-zA-Z0-9]+))\/?|([^\/\.]+))" />
		<cfset local.regexes.optFormatWithOptSlash = "((?:\.)[^\.\?\/]+)?\/?" /><!--- for ".json[/]" support --->
		<!---
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
		--->

		<cfloop array="#local.uriChunks#" index="local.chunk">
			<cfif left(local.chunk, 1) neq "{" or right(local.chunk, 1) neq "}">
				<!--- not a token --->
				<cfset local.uriMatcher = local.uriMatcher & '/' & local.chunk />
			<cfelse>
				<!--- strip {curly braces} --->
				<cfset local.chunk = left(right(local.chunk, len(local.chunk)-1), len(local.chunk)-2) />
				<!--- it's a token... but which kind? --->
				<cfif find(':', local.chunk) neq 0>
					<cfset local.pattern = '(' & listRest(local.chunk, ':') & ')' /><!--- make sure we capture the value --->
					<cfset local.tokenName = listFirst(local.chunk, ':') />
				<cfelse>
					<cfset local.pattern = local.regexes.segment />
					<cfset local.tokenName = local.chunk />
				</cfif>
				<cfset local.uriMatcher = local.uriMatcher & '/' & local.pattern />
				<cfset arrayAppend(local.returnData.tokens, local.tokenName) />
			</cfif>
		</cfloop>

		<!--- if uriRegex ends with a token, slip the format piece in there too... --->
		<cfset local.uriRegex = "^" & local.uriMatcher />
		<cfif right(local.uriRegex, 8) eq local.regexes.segment>
			<cfset local.uriRegex = left(local.uriRegex, len(local.uriRegex)-8) & local.regexes.segmentWithOptFormat />
		</cfif>

		<!--- require the uri to terminate after specified content --->
		<cfset local.uriRegex = local.uriRegex & local.regexes.optFormatWithOptSlash & "$" />

		<cfset local.returnData.uriRegex = local.uriRegex />
		<cfreturn local.returnData />
	</cffunction>

	<cffunction name="sortURIMatchOrder" access="private" output="false">
		<cfargument name="endpoints" />
		<cfset var URIMatchOrder = listToArray( structKeyList(arguments.endpoints, chr(10)), chr(10) ) />
		<cfset arraySort(URIMatchOrder, "textnocase", "desc") />
		<cfreturn URIMatchOrder />
	</cffunction>

	<cffunction name="matchURI" access="private" output="false" returnType="string">
		<cfargument name="requestedURI" type="string" required="true" hint="probably just pass in cgi.path_info" />
		<cfset var local = {} />
		<cfset local.uriCount = arrayLen(application._taffy.URIMatchOrder) />
		<cfloop from="1" to="#local.uriCount#" index="local.i">
			<cfset local.attempt = reMatchNoCase(application._taffy.URIMatchOrder[local.i], arguments.requestedURI) />
			<cfif arrayLen(local.attempt) gt 0>
				<!--- found our mapping --->
				<cfreturn application._taffy.URIMatchOrder[local.i] />
			</cfif>
		</cfloop>
		<!--- nothing found --->
		<cfreturn "" />
	</cffunction>

	<cffunction name="getRequestBody" access="private" output="false" hint="Gets request body data, which CF doesn't do automatically for some verbs">
		<!--- Special thanks to Jason Dean (@JasonPDean) and Ray Camden (@ColdFusionJedi) who helped me figure out how to do this --->
		<cfset var body = getHTTPRequestData().content />
		<!--- on input with content-type "application/json" CF seems to expose it as binary data. Here we convert it back to plain text --->
		<cfif isBinary(body)>
			<cfset body = charsetEncode(body, "UTF-8") />
		</cfif>
		<cfreturn body />
	</cffunction>

	<cffunction name="contentTypeIsSupported" access="private" output="false">
		<cfargument name="contentType" type="string" />
		<cfset var ct = listFirst(arguments.contentType, ";") />
		<cfreturn structKeyExists(application._taffy.contentTypes, ct) />
	</cffunction>

	<cffunction name="getDeserialized" access="private" output="false">
		<cfargument name="body" required="true" />
		<cfargument name="contentType" required="true" />
		<cfset var ct = listFirst(arguments.contentType,';') />
		<cfset var fn = application._taffy.contentTypes[ct] />
		<cfset var args = {} />
		<cfset var result = {} />
		<cfset args.body = arguments.body />

		<cfinvoke
			component="#application._taffy.settings.deserializer#"
			method="#fn#"
			argumentcollection="#args#"
			returnvariable="result"
		/>
		<cfreturn result />
	</cffunction>

	<cffunction name="getSupportedContentTypes" access="private" output="false">
		<cfargument name="deserializer" hint="must be the full dot-notation path to the component" />
		<cfreturn _recurse_getSupportedContentTypes(getComponentMetadata(arguments.deserializer)) />
	</cffunction>

	<cffunction name="_recurse_getSupportedContentTypes" access="private" output="false">
		<cfargument name="objMetaData" />
		<cfset var local = StructNew() />
		<cfset local.response = {} />
		<!--- recurse into parents first so that children override parents --->
		<cfif structKeyExists(arguments.objMetaData, "extends")>
			<cfset local.response = _recurse_getSupportedContentTypes(arguments.objMetaData.extends) />
		</cfif>
		<!--- then handle child settings --->
		<cfif structKeyExists(arguments.objMetaData, "functions") and isArray(arguments.objMetaData.functions)>
			<cfset local.funcs = arguments.objMetaData.functions />
			<cfloop from="1" to="#arrayLen(local.funcs)#" index="local.f">
				<!--- for every function whose name starts with "getFrom" *and* has a taffy_mime metadata attribute, count it --->
				<cfset local.mime = '' />
				<cfif structKeyExists(local.funcs[local.f], "taffy_mime")>
					<cfset local.mime = local.funcs[local.f].taffy_mime />
				<cfelseif structKeyExists(local.funcs[local.f], "taffy:mime")>
					<cfset local.mime = local.funcs[local.f]["taffy:mime"] />
				</cfif>
				<cfif ucase(left(local.funcs[local.f].name, 7)) eq "GETFROM" and len(local.mime)>
					<cfloop list="#local.mime#" delimiters=",;" index="local.m">
						<cfset local.response[local.m] = local.funcs[local.f].name />
					</cfloop>
				</cfif>
			</cfloop>
		</cfif>
		<cfreturn local.response />
	</cffunction>

	<cffunction name="buildRequestArguments" access="private" output="false" returnType="struct">
		<cfargument name="regex" type="string" required="true" hint="regex that describes the request (including uri and query string parameters)" />
		<cfargument name="tokenNamesArray" type="array" required="true" hint="array of token names associated with the matched uri" />
		<cfargument name="uri" type="string" required="true" hint="the requested uri" />
		<cfargument name="queryString" type="string" required="true" hint="any query string parameters included in the request" />
		<cfargument name="headers" type="struct" required="true" hint="any headers included in the request" />

		<cfset var local = StructNew() />
		<cfset var tmp = "" />
		<cfset local.returnData = StructNew() /><!--- this will be used as an argumentCollection for the method that ultimately gets called --->

		<!--- parse path_info data into key-value pairs --->
		<cfset local.tokenValues = reFindNoSuck(arguments.regex, arguments.uri) />
		<cfset local.numTokenValues = arrayLen(local.tokenValues) />
		<cfset local.numTokenNames = arrayLen(arguments.tokenNamesArray) />
		<cfif local.numTokenNames gt 0>
			<cfloop from="1" to="#local.numTokenNames#" index="local.t">
				<cfset local.returnData[arguments.tokenNamesArray[local.t]] = local.tokenValues[local.t] />
			</cfloop>
		</cfif>
		<!--- query_string input is also key-value pairs --->
		<cfloop list="#arguments.queryString#" delimiters="&" index="local.t">
			<cfset local.qsKey = urlDecode(listFirst(local.t,'=')) />
			<cfset local.qsValue = "" />
			<cfif listLen(local.t,'=') eq 2>
				<cfset local.qsValue = urlDecode(listLast(local.t,'=')) />
			</cfif>
			<cfif (len(local.qsKey) gt 2) and (right(local.qsKey, 2) eq "[]")>
				<cfset local.qsKey = left(local.qsKey, len(local.qsKey) - 2) />
				<cfif not structKeyExists(local.returnData, local.qsKey)>
					<cfset local.returnData[local.qsKey] = arrayNew(1) />
				</cfif>
				<cfset arrayAppend(local.returnData[local.qsKey], local.qsValue) />
			<cfelse>
				<cfset local.returnData[local.qsKey] = local.qsValue />
			</cfif>
		</cfloop>
		<!--- if a mime type is requested as part of the url ("whatever.json"), then extract that so taffy can use it --->
		<cfif local.numTokenValues gt local.numTokenNames><!--- when there is 1 more token value than name, that value (regex capture group) is the format --->
			<cfset local.mime = local.tokenValues[local.numTokenValues] />
			<cfset local.returnData["_taffy_mime"] = local.mime />
		<cfelseif structKeyExists(arguments.headers, "Accept")>
			<cfset local.headerMatch = false />
			<cfloop list="#arguments.headers.accept#" index="tmp">
				<!--- deal with that q=0 stuff (just ignore it) --->
				<cfif listLen(tmp, ";") gt 1>
					<cfset tmp = listFirst(tmp, ";") />
				</cfif>
				<cfif structKeyExists(application._taffy.settings.mimeTypes, tmp)>
					<cfset local.returnData["_taffy_mime"] = application._taffy.settings.mimeTypes[tmp] />
					<cfset local.headerMatch = true />
					<cfbreak /><!--- exit loop --->
				<cfelseif trim(tmp) eq "*/*">
					<cfset local.returnData["_taffy_mime"] = application._taffy.settings.defaultMime />
					<cfset local.headerMatch = true />
					<cfbreak /><!--- exit loop --->
				</cfif>
			</cfloop>
			<!--- if a header is passed, but it didn't match any known mimes, and no mime was found via extension, just use whatever's in the header --->
			<cfif local.headerMatch eq false>
				<cfset local.returnData["_taffy_mime"] = listFirst(listFirst(arguments.headers.accept, ","), ";") />
			</cfif>
		</cfif>
		<cfreturn local.returnData />
	</cffunction>

	<cffunction name="guessResourcesPath" access="private" output="false" returntype="string" hint="used to try and figure out the absolute path of the /resources folder even though this file may not be in the web root">
		<!--- if /resources has been explicitly defined in an server/application mapping, it should take precedence --->
		<cfif directoryExists(expandPath("resources"))>
			<cfreturn "resources" />
		<cfelseif directoryExists(expandPath("/resources"))>
			<cfreturn "/resources" />
		</cfif>

		<!--- if all else fails, fall through to guessing where /resources lives --->
		<cfset local.indexcfmpath = cgi.script_name />
		<cfset local.resourcesPath = listDeleteAt(local.indexcfmpath, listLen(local.indexcfmpath, "/"), "/") & "/resources" />

		<cfif GetContextRoot() NEQ "">
			<cfset local.resourcesPath = ReReplace(local.resourcesPath,"^#GetContextRoot()#","")>
		</cfif>

		<cfreturn local.resourcesPath />
	</cffunction>

	<cffunction name="guessResourcesFullPath" access="private" output="false" returntype="string">
		<cfreturn expandPath(guessResourcesPath()) />
	</cffunction>

	<cffunction name="guessResourcesCFCPath" access="private" output="false" returntype="string">
		<cfset var path = guessResourcesPath() />
		<cfif left(path, 1) eq "/"><cfset path = right(path, len(path)-1) /></cfif>
		<cfreturn reReplace(path, "\/", ".", "all") />
	</cffunction>

	<cffunction name="throwError" access="private" output="false" returntype="void">
		<cfargument name="statusCode" type="numeric" default="500" />
		<cfargument name="msg" type="string" required="true" hint="message to return to api consumer" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfcontent reset="true" />
		<cfset addHeaders(arguments.headers) />
		<cfheader statuscode="#arguments.statusCode#" statustext="#arguments.msg#" />
		<cfabort />
	</cffunction>

	<cffunction name="splitURIs" access="private" returntype="array" output="false">
		<cfargument name="input" type="string" required="true" />

		<cfset var inBracketCount = 0 />
		<cfset var output = [] />
		<cfset var s = createObject("java", "java.lang.StringBuffer").init("") />
		<cfset var c = "" />
		<cfloop array="#trim(input).toCharArray()#" index="c">
			<cfif c EQ "{">
				<cfset inBracketCount += 1 />
			<cfelseif c EQ "}" AND inBracketCount GT 0>
				<cfset inBracketCount -= 1 />
			</cfif>
			<cfif c EQ "," AND inBracketCount EQ 0>
				<cfset arrayAppend(output, s.toString()) />
				<cfset s.setLength(0) />
			<cfelse>
				<cfset s.append(c) />
			</cfif>
		</cfloop>
		<cfif s.length() GT 0>
			<cfset arrayAppend(output, s.toString()) />
		</cfif>
	<cfreturn output />
	</cffunction>

	<cffunction name="throwExceptionIfURIDoesntBeginWithForwardSlash" output="false" access="private" returntype="void">
		<cfargument name="uri" type="string" required="true">
		<cfargument name="beanName" type="string" required="true">

		<cfset var uriDoesntBeginWithForwardSlash = left(arguments.uri,1) neq "/">

		<cfif uriDoesntBeginWithForwardSlash>
			<cfthrow
				message="URI doesn't begin with a forward slash."
				detail="The URI (#arguments.uri#) for `#arguments.beanName#` should begin with a forward slash."
				errorcode="taffy.resources.URIDoesntBeginWithForwardSlash"
			/>
		</cfif>
	</cffunction>

	<cffunction name="cacheBeanMetaData" access="private" output="false">
		<cfargument name="factory" required="true" />
		<cfargument name="beanList" type="string" required="true" />
		<cfargument name="taffyRef" type="any" required="True" />
		<cfset var local = StructNew() />
		<cfset local.endpoints = StructNew() />
		<cfloop list="#arguments.beanList#" index="local.beanName">
			<!--- get the cfc metadata that defines the uri for that cfc --->
			<cfset local.cfcMetadata = getMetaData(arguments.factory.getBean(local.beanName)) />
			<cfset local.uriAttr = '' />
			<cfif structKeyExists(local.cfcMetadata, "taffy_uri")>
				<cfset local.uriAttr = local.cfcMetadata["taffy_uri"] />
			<cfelseif structKeyExists(local.cfcMetadata, "taffy:uri")>
				<cfset local.uriAttr = local.cfcMetadata["taffy:uri"] />
			</cfif>

			<cfset local.uris = splitURIs(local.uriAttr) />

			<cfif structKeyExists(local.cfcMetaData, "taffy:aopbean")>
				<cfset local.cachedBeanName = local.cfcMetaData["taffy:aopbean"] />
			<cfelseif structKeyExists(local.cfcMetaData, "taffy_aopbean")>
				<cfset local.cachedBeanName = local.cfcMetaData["taffy_aopbean"] />
			<cfelse>
				<cfset local.cachedBeanName = local.beanName />
			</cfif>

			<!--- if it doesn't have any uris, then it's not a resource --->
			<cfif arrayLen(local.uris)>
				<cfloop array="#local.uris#" index="local.uri">
					<cftry>
						<cfset local.uri = trim(local.uri) />
						<cfset local.metaInfo = convertURItoRegex(local.uri) />
						<cfif structKeyExists(local.endpoints, local.metaInfo.uriRegex)>
							<cfthrow
								message="Duplicate URI scheme detected. All URIs must be unique (excluding tokens)."
								detail="The URI (#local.uri#) for `#local.beanName#`  conflicts with the existing URI definition of `#local.endpoints[local.metaInfo.uriRegex].beanName#`"
								errorcode="taffy.resources.DuplicateUriPattern"
							/>
						</cfif>

						<cfset throwExceptionIfURIDoesntBeginWithForwardSlash(local.uri, local.beanName)>

						<cfset local.endpoints[local.metaInfo.uriRegex] = { beanName = local.cachedBeanName, tokens = local.metaInfo.tokens, methods = structNew(), srcURI = local.uri } />
						<cfif structKeyExists(local.cfcMetadata, "functions")>
							<cfloop array="#local.cfcMetadata.functions#" index="local.f">
								<cfif local.f.name eq "get" or local.f.name eq "post" or local.f.name eq "put" or local.f.name eq "patch" or local.f.name eq "delete" or local.f.name eq "head" or local.f.name eq "options">
									<cfset local.endpoints[local.metaInfo.uriRegex].methods[local.f.name] = local.f.name />

								<!--- also support future/misc verbs via metadata --->
								<cfelseif structKeyExists(local.f,"taffy:verb")>
									<cfset  local.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy:verb"]] = local.f.name />
								<cfelseif structKeyExists(local.f,"taffy_verb")>
									<cfset  local.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy_verb"]] = local.f.name />
								</cfif>

								<!--- cache any extra function metadata for use in onTaffyRequest --->
								<cfset local.extraMetadata = duplicate(local.f) />
								<cfset structDelete(local.extraMetadata, "name") />
								<cfset structDelete(local.extraMetadata, "parameters") />
								<cfset structDelete(local.extraMetadata, "hint") />
								<cfparam name="local.endpoints['#local.metaInfo.uriRegex#'].metadata" default="#structNew()#" />
								<cfif not structIsEmpty(local.extraMetadata)>
									<cfset local.endpoints[local.metaInfo.uriRegex].metadata[local.f.name] = local.extraMetadata />
								<cfelse>
									<cfset local.endpoints[local.metaInfo.uriRegex].metadata[local.f.name] = StructNew() />
								</cfif>
							</cfloop>
						</cfif>
					<cfcatch>
						<!--- skip cfc's with errors, but save info about them for display in the dashboard --->
						<cfset local.err = structNew() />
						<cfset local.err.resource = local.beanName />
						<cfset local.err.exception = cfcatch />
						<cfset arrayAppend(arguments.taffyRef.status.skippedResources, local.err) />
					</cfcatch>
					</cftry>
				</cfloop>
			</cfif>
		</cfloop>
		<cfreturn local.endpoints />
	</cffunction>

	<cffunction name="getBeanListFromExternalFactory" output="false" access="private" returntype="String">
		<cfargument name="bf" required="true" />
		<cfset var beanFactoryMeta = getMetadata(arguments.bf) />
		<cfif lcase(left(beanFactoryMeta.name, 10)) eq "coldspring">
			<cfreturn getBeanListFromColdSpring( arguments.bf ) />
		<cfelseif beanFactoryMeta.name contains "ioc">
			<!--- this isn't a perfect test (contains "ioc") but it's all we can do for now... --->
			<cfset local.beanInfo = arguments.bf.getBeanInfo().beanInfo />
			<cfset local.beanList = "" />
			<cfloop collection="#local.beanInfo#" item="local.beanName">
				<cfif structKeyExists(local.beanInfo[local.beanName],'name')
					  AND local.beanName NEQ local.beanInfo[local.beanName].name
					  AND isInstanceOf(arguments.bf.getBean(local.beanName),'taffy.core.resource')>
					<cfset local.beanList = listAppend(local.beanList,local.beanName) />
				</cfif>
			</cfloop>
			<cfreturn local.beanList />
		</cfif>
		<cfreturn "" />
	</cffunction>

	<cffunction name="getBeanListFromColdSpring" access="private" output="false" returntype="string">
		<cfargument name="bf" required="true" />
		<cfset var local = StructNew() />
		<cfset local.beans = arguments.bf.getBeanDefinitionList() />
		<cfset local.beanList = "" />
		<cfloop collection="#local.beans#" item="local.beanName">
			<!---
				Can't call instanceOf() method on beans generated by factories; there is no
				class property on factory-generated beans, and it throws an error in ColdSpring 1.2.
				Temporary patch is to skip those beans, but we'd really either want to examine the
				return type metadata on the factory method or find some other way to determine if
				this is a Taffy bean.
			 --->
			<cfif (local.beans[local.beanName].getBeanClass() NEQ "")>
				<cfif (local.beans[local.beanName].instanceOf('taffy.core.resource'))>
					<cfset local.beanList = listAppend(local.beanList, local.beanName) />
				</cfif>
			</cfif>
		</cfloop>
		<cfreturn local.beanList />
	</cffunction>

	<cffunction name="inspectMimeTypes" access="private" output="false">
		<cfargument name="customClassDotPath" type="string" required="true" hint="dot-notation path of representation class" />
		<cfargument name="factory" required="true" />
		<cfif arguments.factory.containsBean(arguments.customClassDotPath)>
			<cfreturn _recurse_inspectMimeTypes(getMetadata(arguments.factory.getBean(arguments.customClassDotPath))) />
		<cfelse>
			<cfreturn _recurse_inspectMimeTypes(getComponentMetadata(arguments.customClassDotPath)) />
		</cfif>
	</cffunction>

	<cffunction name="_recurse_inspectMimeTypes" output="false" access="private">
		<cfargument name="objMetaData" type="struct" required="true" />
		<cfargument name="data" type="struct" default="#StructNew()#" />
		<cfset var local = StructNew() />
		<cfset local.ext = '' />
		<cfparam name="arguments.data.mimeTypes" default="#StructNew()#" />
		<cfparam name="arguments.data.mimeExtensions" default="#StructNew()#" />
		<cfparam name="arguments.data.defaultMime" default="" />
		<!--- recurse into parents first so that child defaults override parent defaults --->
		<cfif structKeyExists(arguments.objMetaData, "extends")>
			<cfset arguments.data = _recurse_inspectMimeTypes(arguments.objMetaData.extends, arguments.data) />
		</cfif>
		<!--- then handle child settings --->
		<cfif structKeyExists(arguments.objMetaData, "functions") and isArray(arguments.objMetaData.functions)>
			<cfset local.funcs = arguments.objMetaData.functions />
			<cfloop from="1" to="#arrayLen(local.funcs)#" index="local.f">
				<!--- for every function whose name starts with "getAs" *and* has a taffy_mime metadata attribute, register the mime type --->
				<cfset local.mime = '' />
				<cfif structKeyExists(local.funcs[local.f], "taffy_mime")>
					<cfset local.mime = local.funcs[local.f].taffy_mime />
				<cfelseif structKeyExists(local.funcs[local.f], "taffy:mime")>
					<cfset local.mime = local.funcs[local.f]["taffy:mime"] />
				</cfif>
				<cfif ucase(left(local.funcs[local.f].name, 5)) eq "GETAS" and len(local.mime)>
					<cfset local.ext = lcase(right(local.funcs[local.f].name, len(local.funcs[local.f].name)-5)) />
					<cfset local.mime = lcase(local.mime) />
					<cfloop list="#local.mime#" delimiters=",;" index="local.thisMime">
						<cfparam name="arguments.data.mimeExtensions['#local.ext#']" default="#local.thisMime#" />
						<cfset arguments.data.mimeTypes[local.thisMime] = local.ext />
					</cfloop>
					<!--- check for taffy_default metadata to set the current mime as the default --->
					<cfif structKeyExists(local.funcs[local.f], "taffy_default") and local.funcs[local.f].taffy_default>
						<cfset arguments.data.defaultMime = local.ext />
					<cfelseif structKeyExists(local.funcs[local.f], "taffy:default") and local.funcs[local.f]["taffy:default"] eq true>
						<cfset arguments.data.defaultMime = local.ext />
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<cfreturn arguments.data />
	</cffunction>

	<cffunction name="mimeSupported" output="false" access="private" returntype="boolean">
		<cfargument name="mimeExt" type="string" required="true" />
		<cfif structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)>
			<cfreturn true />
		</cfif>
		<cfif structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)>
			<cfreturn true />
		</cfif>
		<cfreturn false />
	</cffunction>

	<cffunction name="getReturnMimeAsHeader" output="false" access="private">
		<cfargument name="mimeExt" type="string" required="true" />
		<cfif structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)>
			<cfreturn application._taffy.settings.mimeExtensions[arguments.mimeExt] />
		</cfif>
		<cfif structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)>
			<cfreturn arguments.mimeExt />
		</cfif>
	</cffunction>

	<cffunction name="getReturnMimeAsExt" output="false" access="private">
		<cfargument name="mimeExt" type="string" required="true" />
		<cfif structKeyExists(application._taffy.settings.mimeExtensions, arguments.mimeExt)>
			<cfreturn arguments.mimeExt />
		</cfif>
		<cfif structKeyExists(application._taffy.settings.mimeTypes, arguments.mimeExt)>
			<cfreturn application._taffy.settings.mimeTypes[arguments.mimeExt] />
		</cfif>
	</cffunction>

	<cffunction name="isUnhandledPathRequest" access="private" returntype="boolean">
		<cfargument name="targetPath" />
		<cfreturn REFindNoCase( "^(" & application._taffy.settings.unhandledPathsRegex & ")", arguments.targetPath ) />
	</cffunction>

	<cffunction name="reFindNoSuck" output="false" access="private" hint="I wrote this wrapper for reFindNoCase because the way it returns matches is god awful.">
		<cfargument name="pattern" required="true" type="string" />
		<cfargument name="data" required="true" type="string" />
		<cfargument name="startPos" required="false" default="1" />
		<cfscript>
			var local = StructNew();
			local.awesome = arrayNew(1);
			local.sucky = refindNoCase(arguments.pattern, arguments.data, arguments.startPos, true);
			if (not isArray(local.sucky.len) or arrayLen(local.sucky.len) eq 0){return arrayNew(1);} //handle no match at all
			for (local.i=1; local.i<= arrayLen(local.sucky.len); local.i++){
				//if there's a match with pos 0 & length 0, that means the mime type was not specified
				if (local.sucky.len[local.i] gt 0 && local.sucky.pos[local.i] gt 0){
					//don't include the group that matches the entire pattern
					local.matchBody = mid(arguments.data, local.sucky.pos[local.i], local.sucky.len[local.i]);
					if (local.matchBody neq arguments.data){
						arrayAppend( local.awesome, local.matchBody );
					}
				}
			}
			return local.awesome;
		</cfscript>
	</cffunction>

	<!---
		helper methods: stuff used in Application.cfc
	--->
	<cffunction name="getBeanFactory" access="private" output="false">
		<cfreturn application._taffy.factory />
	</cffunction>

	<cffunction name="getExternalBeanFactory" access="private" output="false">
		<cfreturn application._taffy.externalBeanFactory />
	</cffunction>

	<cffunction name="newRepresentation" access="private" output="false" hint="private as of 3.0">
		<cfset var repClass = application._taffy.settings.serializer />
		<cfif application._taffy.factory.containsBean(repClass)>
			<cfreturn application._taffy.factory.getBean(repClass) />
		<cfelse>
			<cfreturn createObject("component", repClass) />
		</cfif>
	</cffunction>

	<cffunction name="noData" access="public" output="false">
		<cfreturn newRepresentation().noData() />
	</cffunction>

	<cffunction name="noContent" access="public" output="false">
		<cfreturn newRepresentation().noContent() />
	</cffunction>

	<cffunction name="representationOf" access="public" output="false">
		<cfargument name="data" required="true" />
		<cfreturn newRepresentation().setData( arguments.data ) />
	</cffunction>

	<cffunction name="rep" access="public" output="false" hint="alias for representationOf">
		<cfargument name="data" required="true" />
		<cfreturn representationOf(arguments.data) />
	</cffunction>

	<cffunction name="getGlobalHeaders" access="private" output="false" returntype="Struct">
		<cfreturn application._taffy.settings.globalHeaders />
	</cffunction>

	<cfif NOT isDefined("getComponentMetadata")>
		<!--- workaround for platforms where getComponentMetadata doesn't exist --->
		<cffunction name="tmp">
			<cfreturn getMetaData(createObject("component",arguments[1])) />
		</cffunction>
		<cfset this.getComponentMetadata = tmp />
	</cfif>

	<cffunction name="getPath" output="false" access="public" returntype="String"
		hint="This method returns just the URI portion of the URL, and makes it easier to port Taffy to other
		platforms by subclassing this method to match the way the platform works. The default behavior is
		tested and works on Adobe ColdFusion 9.0.1.">
		<cfif cgi.path_info eq cgi.script_name>
			<!--- WTF! I've only seen this on Win+IIS, seems fine on OSX+Apache... --->
			<cfreturn "" />
		</cfif>
		<cfreturn cgi.path_info />
	</cffunction>

	<cffunction name="addHeaders" access="public" output="false" returntype="void">
		<cfargument name="headers" type="struct" required="true" />
		<cfset var h = '' />
		<cfif !structIsEmpty(arguments.headers)>
			<cfloop list="#structKeyList(arguments.headers)#" index="h">
				<cfheader name="#h#" value="#arguments.headers[h]#" />
			</cfloop>
		</cfif>
	</cffunction>

	<cffunction name="getBasicAuthCredentials" access="public" output="false" returntype="Struct">
		<cfset var local = {} />
		<cfset local.credentials = {} />
		<cfset local.credentials.username = "" />
		<cfset local.credentials.password = "" />
		<cftry>
			<cfset local.encodedCredentials = ListLast( GetPageContext().getRequest().getHeader("Authorization"), " " ) />
			<cfset local.decodedCredentials = toString( toBinary( local.EncodedCredentials ), "iso-8859-1" ) />
			<cfset local.credentials.username = listFirst( local.decodedCredentials, ":" ) />
			<cfset local.credentials.password = listRest( local.decodedCredentials, ":" ) />
			<cfcatch></cfcatch>
		</cftry>
		<cfreturn local.credentials />
	</cffunction>

	<cffunction name="getHostname"><!--- unceremoniously stolen from FW/1 --->
		<cfreturn createObject( "java", "java.net.InetAddress" ).getLocalHost().getHostName() />
	</cffunction>

	<cffunction name="getHintsFromMetaData" output="false">
		<cfargument name="metadata" type="struct" required="true" />
		<cfset var result = StructNew() />
		<cfset var func = '' />
		<cfset var f = 0 />
		<cfset var g = 0 />
		<cfset var foundFunc = false />
		<cfset result.functions = arrayNew(1) />
		<!--- don't recurse if we've reached the base component --->
		<cfif structKeyExists(metadata, "extends") and not metadata.extends.fullname eq "taffy.core.resource">
			<cfset result = getHintsFromMetaData(metadata.extends) />
		</cfif>
		<!--- component attributes --->
		<cfif structKeyExists(arguments.metadata, "hint")>
			<!--- intentionally overwrite hint from any parent cfc's --->
			<cfset result.hint = arguments.metadata.hint />
		</cfif>
		<!--- get uri --->
		<cfif structKeyExists(arguments.metadata, "taffy_uri")>
			<cfset result.uri = arguments.metadata.taffy_uri />
		</cfif>
		<cfif structKeyExists(arguments.metadata, "taffy:uri")>
			<cfset result.uri = arguments.metadata['taffy:uri'] />
		</cfif>
		<!--- if there aren't any functions here to grab, return what we already have --->
		<cfif not structKeyExists (metadata,'functions') or not isArray(metadata.functions) or not arrayLen(metadata.functions)>
			<cfreturn result />
		</cfif>
		<cfloop from="1" to="#arrayLen(metadata.functions)#" index="f">
			<cfset func = metadata.functions[f] />
			<!--- ignore hidden methods, if access is not set, assume public --->
			<cfif not structKeyExists(func, "access") or (func.access neq "private" and func.access neq "package")>
				<!--- check to see if this function is already in the list. If so, overwrite, otherwise append --->
				<cfset foundFunc = False />
				<cfloop from="1" to="#arrayLen( result.functions )#" index="g">
					<cfif result.functions[g].NAME EQ func.NAME>
						<cfset result.functions[g] = func />
						<cfset foundFunc = True />
						<cfbreak />
					</cfif>
				</cfloop>
				<cfif NOT foundFunc>
					<cfset arrayAppend(result.functions, func) />
				</cfif>
			</cfif>
		</cfloop>
		<cfreturn result />

	</cffunction>

</cfcomponent>
