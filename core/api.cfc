<cfcomponent hint="Base class for taffy REST application's Application.cfc">

	<!--- this method is meant to be (optionally) overrided in your application.cfc --->
	<cffunction name="getEnvironment" output="false" hint="override this function to define the current API environment"><cfreturn "" /></cffunction>

	<!---
		onTaffyRequest gives you the opportunity to inspect the request before it is sent to the service.
		If you override this function, you MUST either return TRUE or a representation object
		(eg either taffy.core.nativeJsonRepresentation or your default representation class)
	--->
	<cffunction name="onTaffyRequest" output="false">
		<cfargument name="verb" />
		<cfargument name="cfc" />
		<cfargument name="requestArguments" />
		<cfargument name="mimeExt" />
		<cfargument name="headers" />
		<cfreturn true />
	</cffunction>

	<!--- Your Application.cfc should override this method AND call super.onApplicationStart() --->
	<cffunction name="onApplicationStart">
		<cfset setupFramework() />
		<cfreturn true />
	</cffunction>

	<!--- Your Application.cfc should override this method AND call super.onRequestStart(targetpath) --->
	<cffunction name="onRequestStart">
		<cfargument name="targetPath" />
		<cfset var local = structNew() />
		<cfset local.reloadedInThisRequest = false />
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
			<cfif !local.reloadedInThisRequest><!--- prevent double reloads --->
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
					<cfinclude template="../dashboard/dashboard.cfm" />
					<cfabort />
				<cfelse>
					<cfif len(application._taffy.settings.disabledDashboardRedirect)>
						<cflocation url="#application._taffy.settings.disabledDashboardRedirect#" addtoken="false" />
						<cfabort />
					<cfelse>
						<cfset throwError(403, "Forbidden") />
					</cfif>
				</cfif>
			</cfif>
		<cfelse>
			<!--- allow pass-thru for selected paths --->
			<cfset structDelete(this, 'onRequest') />
			<cfset structDelete(variables, 'onRequest') />
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
				<cfdump var="#cfcatch#" format="text" />
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- short-circuit logic --->
	<cffunction name="onRequest" output="true" returntype="boolean">
		<cfargument name="targetPage" type="string" required="true" />

		<cfset var _taffyRequest = {} />
		<cfset var local = {} />

		<!--- enable/disable debug output per settings --->
		<cfif not structKeyExists(url, application._taffy.settings.debugKey)>
			<cfsetting showdebugoutput="false" />
		</cfif>

		<!--- display api dashboard if requested --->
		<cfif
			NOT structKeyExists(url,application._taffy.settings.endpointURLParam)
			AND NOT structKeyExists(form,application._taffy.settings.endpointURLParam)
			AND len(cgi.path_info) lte 1
			AND listFindNoCase(cgi.script_name, "index.cfm", "/") EQ listLen(cgi.script_name, "/")>
			<cfif NOT application._taffy.settings.disableDashboard>
				<cfinclude template="../dashboard/dashboard.cfm" />
				<cfabort />
			<cfelse>
				<cfif len(application._taffy.settings.disabledDashboardRedirect)>
					<cflocation url="#application._taffy.settings.disabledDashboardRedirect#" addtoken="false" />
					<cfabort />
				<cfelse>
					<cfset throwError(403, "Forbidden") />
				</cfif>
			</cfif>
		</cfif>

		<!--- get request details --->
		<cfset _taffyRequest = parseRequest() />

		<!--- CORS headers (so that CORS can pass even if the resource throws an exception) --->
		<cfset local.allowVerbs = uCase(structKeyList(_taffyRequest.matchDetails.methods)) />
		<cfif application._taffy.settings.allowCrossDomain
				AND listFindNoCase('PUT,DELETE,OPTIONS',_taffyRequest.verb)
				AND NOT listFind(local.allowVerbs,'OPTIONS')>
		    <cfset local.allowVerbs = listAppend(local.allowVerbs,'OPTIONS') />
		</cfif>
		<cfif application._taffy.settings.allowCrossDomain>
			<cfheader name="Access-Control-Allow-Origin" value="*" />
			<cfheader name="Access-Control-Allow-Methods" value="#local.allowVerbs#" />
			<!--- Why do we parrot back these headers? See: https://github.com/atuttle/Taffy/issues/144 --->
			<cfif not structKeyExists(_taffyRequest.headers, "Access-Control-Request-Headers")>
				<cfheader name="Access-Control-Allow-Headers" value="Origin, Authorization, X-Requested-With, Content-Type, X-HTTP-Method-Override, Accept, Referrer, User-Agent" />
			<cfelse>
				<!--- parrot back all of the request headers to allow the request to continue (can we improve on this?) --->
				<cfset local.allowedHeaders = {} />
				<cfloop list="Origin,Authorization,X-Requested-With,Content-Type,X-HTTP-Method-Override,Accept,Referrer,User-Agent" index="local.h">
					<cfset local.allowedHeaders[local.h] = 1 />
				</cfloop>
				<cfset local.requestedHeaders = _taffyRequest.headers['Access-Control-Request-Headers'] />
				<cfloop list="#local.requestedHeaders#" index="local.i">
					<cfset local.allowedHeaders[ local.i ] = 1 />
				</cfloop>
				<cfheader name="Access-Control-Allow-Headers" value="#structKeyList(local.allowedHeaders)#" />
			</cfif>
		</cfif>

		<!--- global headers --->
		<cfset addHeaders(getGlobalHeaders()) />

		<!---
			Now we know everything we need to know to service the request. let's service it!
		--->

		<!--- ...after we let the api developer know all of the request details first... --->
		<cfset _taffyRequest.continue = onTaffyRequest(
			_taffyRequest.verb,
			_taffyRequest.matchDetails.beanName,
			_taffyRequest.requestArguments,
			_taffyRequest.returnMimeExt,
			_taffyRequest.headers
		) />

		<cfif not structKeyExists(_taffyRequest, "continue")>
			<!--- developer forgot to return true --->
			<cfthrow
				message="Error in your onTaffyRequest method"
				detail="Your onTaffyRequest method returned no value. Expected: TRUE or a Representation Object."
				errorcode="400"
			/>
		</cfif>

		<cfif isObject(_taffyRequest.continue)>
			<!--- inspection complete but request has been aborted by developer; return custom response --->
			<cfset _taffyRequest.result = duplicate(_taffyRequest.continue) />
			<cfset structDelete(_taffyRequest, "continue")/>
		<cfelse>
			<!--- inspection complete and request allowed by developer; send request to service --->

			<cfif structKeyExists(_taffyRequest.matchDetails.methods, _taffyRequest.verb)>
				<!--- returns a representation-object --->
				<cfinvoke
					component="#application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName)#"
					method="#_taffyRequest.method#"
					argumentcollection="#_taffyRequest.requestArguments#"
					returnvariable="_taffyRequest.result"
				/>
			<cfelseif NOT listFind(local.allowVerbs,_taffyRequest.verb)>
				<!--- if the verb is not implemented, refuse the request --->
				<cfheader name="ALLOW" value="#local.allowVerbs#" />
				<cfset throwError(405, "Method Not Allowed") />
			<cfelse>
				<!--- create dummy response for cross domain OPTIONS request --->
				<cfset _taffyRequest.resultHeaders = structNew() />
				<cfset _taffyRequest.statusArgs = structNew() />
				<cfset _taffyRequest.statusArgs.statusCode = 200 />
				<cfset _taffyRequest.statusArgs.statusText = 'OK' />
			</cfif>

		</cfif>
		<!--- make sure the requested mime type is available --->
		<cfif not mimeSupported(_taffyRequest.returnMimeExt)>
			<cfset throwError(400, "Requested format not available (#_taffyRequest.returnMimeExt#)") />
		</cfif>

		<cfif structKeyExists(_taffyRequest,'result')>
			<!--- get status code --->
			<cfset _taffyRequest.statusArgs = structNew() />
			<cfset _taffyRequest.statusArgs.statusCode = _taffyRequest.result.getStatus() />
			<cfset _taffyRequest.statusArgs.statusText = _taffyRequest.result.getStatusText() />
			<!--- get custom headers --->
			<cfinvoke
				component="#_taffyRequest.result#"
				method="getHeaders"
				returnvariable="_taffyRequest.resultHeaders"
			/>
		</cfif>

		<cfsetting enablecfoutputonly="true" />
		<cfcontent reset="true" type="#getReturnMimeAsHeader(_taffyRequest.returnMimeExt)#; charset=utf-8" />
		<cfheader statuscode="#_taffyRequest.statusArgs.statusCode#" statustext="#_taffyRequest.statusArgs.statusText#" />

		<!--- headers --->
		<cfset addHeaders(_taffyRequest.resultHeaders) />

		<!--- add ALLOW header for current resource, which describes available verbs --->
		<cfheader name="ALLOW" value="#local.allowVerbs#" />

		<!--- result data --->
		<cfif structKeyExists(_taffyRequest,'result')>
			<cfset _taffyRequest.resultType = _taffyRequest.result.getType() />

			<cfif _taffyRequest.resultType eq "textual">
				<!--- serialize the representation's data into the requested mime type --->
				<cfinvoke
					component="#_taffyRequest.result#"
					method="getAs#_taffyRequest.returnMimeExt#"
					returnvariable="_taffyRequest.resultSerialized"
				/>

				<!--- apply jsonp wrapper if requested --->
				<cfif structKeyExists(_taffyRequest, "jsonpCallback")>
					<cfset _taffyRequest.resultSerialized = _taffyRequest.jsonpCallback & "(" & _taffyRequest.resultSerialized & ");" />
				</cfif>

				<!--- don't return data if etags are enabled and the data hasn't changed --->
				<cfif application._taffy.settings.useEtags and _taffyRequest.verb eq "GET">
					<cfif structKeyExists(_taffyRequest.headers, "If-None-Match")>
						<cfset _taffyRequest.clientEtag = _taffyRequest.headers['If-None-Match'] />
						<cfset _taffyRequest.serverEtag = _taffyRequest.result.getData().hashCode() />
						<cfif len(_taffyRequest.clientEtag) gt 0 and _taffyRequest.clientEtag eq _taffyRequest.serverEtag>
							<cfheader statuscode="304" statustext="Not Modified" />
							<cfcontent reset="true" type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8" />
							<cfreturn true />
						</cfif>
					<cfelse>
						<cfheader name="Etag" value="#_taffyRequest.result.getData().hashCode()#" />
					</cfif>
				</cfif>

				<cfcontent reset="true" type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#; charset=utf-8" />
				<cfif _taffyRequest.resultSerialized neq ('"' & '"')>
					<cfoutput>#_taffyRequest.resultSerialized#</cfoutput>
				</cfif>
				<!--- debug output --->
				<cfif structKeyExists(url, application._taffy.settings.debugKey)>
					<cfoutput><h3>Request Details:</h3><cfdump var="#_taffyRequest#"></cfoutput>
				</cfif>

			<cfelseif _taffyRequest.resultType eq "filename">
				<cfcontent reset="true" file="#_taffyRequest.result.getFileName()#" type="#_taffyRequest.result.getFileMime()#" deletefile="#_taffyRequest.result.getDeleteFile()#" />

			<cfelseif _taffyRequest.resultType eq "filedata">
				<cfcontent reset="true" variable="#_taffyRequest.result.getFileData()#" type="#_taffyRequest.result.getFileMime()#" />

			<cfelseif _taffyRequest.resultType eq "imagedata">
				<cfcontent reset="true" variable="#_taffyRequest.result.getImageData()#" type="#_taffyRequest.result.getFileMime()#" />

			</cfif>
		</cfif>
		<cfreturn true />
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- internal methods --->
	<cffunction name="setupFramework" access="private" output="false" returntype="void">
		<cfset var local = structNew() />
		<cfparam name="variables.framework" default="#structNew()#" />
		<cfheader name="X-TAFFY-RELOADED" value="true" />
		<cfset application._taffy = structNew() />
		<cfset application._taffy.version = "2.0.4" />
		<cfset application._taffy.endpoints = structNew() />
		<!--- default settings --->
		<cfset local.defaultConfig = structNew() />
		<cfset local.defaultConfig.defaultMime = "" />
		<cfset local.defaultConfig.debugKey = "debug" />
		<cfset local.defaultConfig.reloadKey = "reload" />
		<cfset local.defaultConfig.reloadPassword = "true" />
		<cfset local.defaultConfig.reloadOnEveryRequest = false />
		<cfset local.defaultConfig.endpointURLParam = 'endpoint' />
		<cfset local.defaultConfig.representationClass = "taffy.core.nativeJsonRepresentation" />
		<cfset local.defaultConfig.dashboardKey = "dashboard" />
		<cfset local.defaultConfig.disableDashboard = false />
		<cfset local.defaultConfig.disabledDashboardRedirect = "" />
		<cfset local.defaultConfig.unhandledPaths = "/flex2gateway" />
		<cfset local.defaultConfig.allowCrossDomain = false />
		<cfset local.defaultConfig.useEtags = false />
		<cfset local.defaultConfig.jsonp = false />
		<cfset local.defaultConfig.globalHeaders = structNew() />
		<cfset local.defaultConfig.mimeTypes = structNew() />
		<cfset local.defaultConfig.returnExceptionsAsJson = true />
		<cfset local.defaultConfig.exceptionLogAdapter = "taffy.bonus.LogToEmail" />
		<cfset local.defaultConfig.exceptionLogAdapterConfig = StructNew() />
		<cfset local.defaultConfig.exceptionLogAdapterConfig.emailFrom = "api-error@yourdomain.com" />
		<cfset local.defaultConfig.exceptionLogAdapterConfig.emailTo = "you@yourdomain.com" />
		<cfset local.defaultConfig.exceptionLogAdapterConfig.emailSubj = "Exception Trapped in API" />
		<cfset local.defaultConfig.exceptionLogAdapterConfig.emailType = "html" />
		<!--- status --->
		<cfset application._taffy.status = structNew() />
		<cfset application._taffy.status.internalBeanFactoryUsed = false />
		<cfset application._taffy.status.externalBeanFactoryUsed = false />
		<cfset application._taffy.uriMatchOrder = [] />
		<!--- allow setting overrides --->
		<cfset application._taffy.settings = structNew() />
		<cfset structAppend(application._taffy.settings, local.defaultConfig, true) /><!--- initialize to default values --->
		<cfset structAppend(application._taffy.settings, variables.framework, true) /><!--- update with user values --->
		<cfif structKeyExists(variables.framework, "beanFactory")>
			<cfset setBeanFactory(variables.framework.beanFactory) />
		</cfif>
		<!--- allow environment-specific config --->
		<cfset local.env = getEnvironment() />
		<cfif len(local.env) gt 0>
			<cfparam name="variables.framework" default="#structNew()#" />
			<cfparam name="variables.framework.environments" default="#structNew()#" />
			<cfif structKeyExists(variables.framework.environments, local.env) and isStruct(variables.framework.environments[local.env])>
				<cfset structAppend(application._taffy.settings, variables.framework.environments[local.env]) />
			</cfif>
		</cfif>
		<!--- translate unhandledPaths config to regex for easier matching (This is ripped off from FW/1. Thanks, Sean!) --->
		<cfset application._taffy.settings.unhandledPathsRegex = replaceNoCase(
			REReplace(application._taffy.settings.unhandledPaths, '(\+|\*|\?|\.|\[|\^|\$|\(|\)|\{|\||\\)', '\\\1', 'all' ),
			',', '|', 'all' )
		/>
		<!--- if resources folder exists, use internal bean factory --->
		<cfset _taffyRequest.resourcePath = guessResourcesFullPath() />
		<cfset local.noResources = false />
		<cfif directoryExists(_taffyRequest.resourcePath)>
			<!--- setup internal bean factory --->
			<cfset application._taffy.factory = createObject("component", "taffy.core.factory").init() />
			<cfset application._taffy.factory.loadBeansFromPath(_taffyRequest.resourcePath, guessResourcesCFCPath(), guessResourcesFullPath(), true) />
			<cfset application._taffy.beanList = application._taffy.factory.getBeanList() />
			<cfset cacheBeanMetaData(application._taffy.factory, application._taffy.beanList) />
			<cfset application._taffy.status.internalBeanFactoryUsed = true />
			<!---
				if both an external bean factory and the internal factory are in use (because of /resources folder),
				resolve dependencies for each bean of internal factory with the external factory's resources
			--->
			<cfif application._taffy.status.externalBeanFactoryUsed>
				<cfset resolveDependencies() />
			</cfif>
		<cfelseif application._taffy.status.externalBeanFactoryUsed>
			<!--- only using external factory, so create a pointer to it --->
			<cfset application._taffy.factory = application._taffy.externalBeanFactory />
			<!--- since external factory is only factory, check it for taffy resources --->
			<cfset local.beanList = getBeanListFromExternalFactory() />
			<cfset cacheBeanMetaData(application._taffy.externalBeanFactory, local.beanList) />
 		<cfelse>
 			<cfset local.noResources = true />
		</cfif>
		<cfif not local.noResources>
			<!--- sort URIs --->
			<cfset sortURIMatchOrder() />
			<!--- automatically introspect mime types from cfc metadata of default representation class --->
			<cfset inspectMimeTypes(application._taffy.settings.representationClass) />
			<!--- check to make sure a default mime type is set --->
			<cfif application._taffy.settings.defaultMime eq "">
				<cfset throwError(400, "You have not specified a default mime type!") />
			</cfif>
		</cfif>
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
				<cfset requestObj.uri = url[application._taffy.settings.endpointURLParam] />

			<cfelseif structKeyExists(form,application._taffy.settings.endpointURLParam)>
				<cfset requestObj.uri = form[application._taffy.settings.endpointURLParam] />
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
		<cfif isDefined("httpMethodOverride")>
		    <cfset requestObj.verb = httpMethodOverride />
		</cfif>

		<cfif structKeyExists(application._taffy.endpoints[requestObj.matchingRegex].methods, requestObj.verb)>
			<cfset requestObj.method = application._taffy.endpoints[requestObj.matchingRegex].methods[requestObj.verb] />
		<cfelse>
			<cfset requestObj.method = "" />
		</cfif>

		<cfset requestObj.body = getRequestBody() />
		<cfset requestObj.contentType = cgi.content_type />
		<cfif len(requestObj.body)>
			<cfif findNoCase("application/x-www-form-urlencoded", requestObj.contentType)>
				<cfif not find('=', requestObj.body)>
					<cfset throwError(400, "You've indicated that you're sending form-encoded data but it doesn't appear to be valid. Aborting request.") />
				</cfif>
				<!--- url-encoded body --->
				<cfset requestObj.queryString = requestObj.body />
			<cfelseif findNoCase("application/json", requestObj.contentType) or findNoCase("text/json", requestObj.contentType)>
				<!--- json-encoded body --->
				<cfif not isJson(requestObj.body)>
					<cfset throwError(msg="Input JSON is not well formed: #requestObj.body#") />
				</cfif>
				<cfset local.tmp = deserializeJSON(requestObj.body) />
				<cfif structKeyExists(local.tmp, "data")>
					<cfset requestObj.bodyArgs = local.tmp.data />
				<cfelse>
					<cfset requestObj.bodyArgs = local.tmp />
				</cfif>
				<cfset requestObj.queryString = cgi.query_string />
			<cfelseif findNoCase("multipart/form-data", requestObj.contentType)>
				<!--- do nothing, to support the way railo handles multipart requests (just avoids the error condition below) --->
				<cfset requestObj.queryString = cgi.query_string />
			<cfelse>
				<cfif isJson(requestObj.body)>
					<cfset throwError(400, "Looks like you're sending JSON data, but you haven't specified a content type. Aborting request.") />
				<cfelse>
					<cfset throwError(400, "You must specify a content-type. Aborting request.") />
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
		<cfset application._taffy.URIMatchOrder = listToArray( structKeyList(application._taffy.endpoints, chr(10)), chr(10) ) />
		<cfset arraySort(application._taffy.URIMatchOrder, "text", "desc") />
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
			<cfif listLen(local.t,'=') eq 2>
				<cfset local.returnData[listFirst(local.t,'=')] = urlDecode(listLast(local.t,'=')) />
			<cfelse>
				<cfset local.returnData[listFirst(local.t,'=')] = "" />
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
		<cfset path = right(path, len(path)-1) />
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

	<cffunction name="cacheBeanMetaData" access="private" output="false" returnType="void">
		<cfargument name="factory" required="true" />
		<cfargument name="beanList" type="string" required="true" />
		<cfset var local = StructNew() />
		<cfloop list="#arguments.beanList#" index="local.beanName">
			<!--- get the cfc metadata that defines the uri for that cfc --->
			<cfset local.cfcMetadata = getMetaData(arguments.factory.getBean(local.beanName)) />
			<cfset local.uri = '' />
			<cfif structKeyExists(local.cfcMetadata, "taffy_uri")>
				<cfset local.uri = local.cfcMetadata["taffy_uri"] />
			<cfelseif structKeyExists(local.cfcMetadata, "taffy:uri")>
				<cfset local.uri = local.cfcMetadata["taffy:uri"] />
			</cfif>

			<cfif structKeyExists(local.cfcMetaData, "taffy:aopbean")>
				<cfset local.cachedBeanName = local.cfcMetaData["taffy:aopbean"] />
			<cfelseif structKeyExists(local.cfcMetaData, "taffy_aopbean")>
				<cfset local.cachedBeanName = local.cfcMetaData["taffy_aopbean"] />
			<cfelse>
				<cfset local.cachedBeanName = local.beanName />
			</cfif>

			<!--- if it doesn't have a uri, then it's not a resource --->
			<cfif len(local.uri)>
				<cfset local.metaInfo = convertURItoRegex(local.uri) />
				<cfif structKeyExists(application._taffy.endpoints, local.metaInfo.uriRegex)>
					<cfthrow
						message="Duplicate URI scheme detected. All URIs must be unique (excluding tokens)."
						detail="The URI for `#local.beanName#` conflicts with the existing URI definition of `#application._taffy.endpoints[local.metaInfo.uriRegex].beanName#`"
						errorcode="taffy.resources.DuplicateUriPattern"
					/>
				</cfif>
				<cfset application._taffy.endpoints[local.metaInfo.uriRegex] = { beanName = local.cachedBeanName, tokens = local.metaInfo.tokens, methods = structNew(), srcURI = local.uri } />
				<cfif structKeyExists(local.cfcMetadata, "functions")>
					<cfloop array="#local.cfcMetadata.functions#" index="local.f">
						<cfif local.f.name eq "get" or local.f.name eq "post" or local.f.name eq "put" or local.f.name eq "delete" or local.f.name eq "head" or local.f.name eq "options">
							<cfset application._taffy.endpoints[local.metaInfo.uriRegex].methods[local.f.name] = local.f.name />

						<!--- also support future/misc verbs via metadata --->
						<cfelseif structKeyExists(local.f,"taffy:verb")>
							<cfset  application._taffy.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy:verb"]] = local.f.name />
						<cfelseif structKeyExists(local.f,"taffy_verb")>
							<cfset  application._taffy.endpoints[local.metaInfo.uriRegex].methods[local.f["taffy_verb"]] = local.f.name />
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="resolveDependencies" access="private" output="false" returnType="void" hint="used to resolve dependencies of internal beans using external bean factory">
		<cfset var local = StructNew() />
		<cfloop list="#structKeyList(application._taffy.endpoints)#" index="local.endpoint">
			<cfset local.bean = application._taffy.factory.getBean(application._taffy.endpoints[local.endpoint].beanName) />
			<cfset local.md = getMetadata( local.bean ) />
			<cfset local.methods = local.md.functions />
			<!--- get list of method names --->
			<cfset local.methodNames = "" />
			<cfloop from="1" to="#arrayLen(local.methods)#" index="local.m">
				<cfset local.methodNames = listAppend(local.methodNames, local.methods[local.m].name) />
			</cfloop>
			<!--- look for setters --->
			<cfloop list="#local.methodNames#" index="local.method">
				<cfif left(local.method, 3) eq "set" and len(local.method) gt 3>
					<!--- we've found a dependency, try to resolve it --->
					<cfset local.beanName = right(local.method, len(local.method) - 3) />
					<cfif application._taffy.externalBeanFactory.containsBean(local.beanName)>
						<cfset local.dependency = application._taffy.externalBeanFactory.getBean(local.beanName) />
						<cfset evaluate("local.bean.#local.method#(local.dependency)") />
					</cfif>
				</cfif>
			</cfloop>
			<!--- also resolve properties --->
			<cfif structKeyExists(local.md, "properties") and isArray(local.md.properties)>
				<cfloop from="1" to="#arrayLen(local.md.properties)#" index="local.p">
					<cfset local.propName = local.md.properties[local.p].name />
					<cfif application._taffy.externalBeanFactory.containsBean(local.propName)>
						<cfset local.bean[local.propName] = application._taffy.externalBeanFactory.getBean(local.propName) />
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="getBeanListFromExternalFactory" output="false" access="private" returntype="String">
		<cfset var beanFactoryMeta = getMetadata(application._taffy.externalBeanFactory) />
		<cfif lcase(left(beanFactoryMeta.name, 10)) eq "coldspring">
			<cfreturn getBeanListFromColdSpring() />
		<cfelseif beanFactoryMeta.name contains "ioc">
			<!--- this isn't a perfect test (contains "ioc") but it's all we can do for now... --->
			<cfset local.beanInfo = application._taffy.externalBeanFactory.getBeanInfo().beanInfo />
			<cfset local.beanList = "" />
			<cfloop collection="#local.beanInfo#" item="local.beanName">
				<cfif structKeyExists(local.beanInfo[local.beanName],'name')
					  AND local.beanName NEQ local.beanInfo[local.beanName].name
					  AND isInstanceOf(application._taffy.externalBeanFactory.getBean(local.beanName),'taffy.core.resource')>
					<cfset local.beanList = listAppend(local.beanList,local.beanName) />
				</cfif>
			</cfloop>
			<cfreturn local.beanList />
		</cfif>
		<cfreturn "" />
	</cffunction>

	<cffunction name="getBeanListFromColdSpring" access="private" output="false" returntype="string">
		<cfset var local = StructNew() />
		<cfset local.beans = application._taffy.externalBeanFactory.getBeanDefinitionList() />
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

	<cffunction name="inspectMimeTypes" access="private" output="false" returntype="void">
		<cfargument name="customClassDotPath" type="string" required="true" hint="dot-notation path of representation class" />
		<cfif application._taffy.factory.containsBean(arguments.customClassDotPath)>
			<cfset _recurse_inspectMimeTypes(getMetadata(application._taffy.factory.getBean(arguments.customClassDotPath))) />
		<cfelse>
			<cfset _recurse_inspectMimeTypes(getComponentMetadata(arguments.customClassDotPath)) />
		</cfif>
	</cffunction>

	<cffunction name="_recurse_inspectMimeTypes" output="false" access="private" returntype="void">
		<cfargument name="objMetaData" type="struct" required="true" />
		<cfset var local = StructNew() />
		<cfset local.ext = '' />
		<!--- recurse into parents first so that child defaults override parent defaults --->
		<cfif structKeyExists(arguments.objMetaData, "extends")>
			<cfset _recurse_inspectMimeTypes(arguments.objMetaData.extends) />
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
					<cfset registerMimeType(local.ext, lcase(local.mime)) />
					<!--- check for taffy_default metadata to set the current mime as the default --->
					<cfif structKeyExists(local.funcs[local.f], "taffy_default") and local.funcs[local.f].taffy_default>
						<cfset setDefaultMime(local.ext) />
					<cfelseif structKeyExists(local.funcs[local.f], "taffy:default") and local.funcs[local.f]["taffy:default"] eq true>
						<cfset setDefaultMime(local.ext) />
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
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
	<cffunction name="setBeanFactory" access="private" output="false" returntype="void">
		<cfargument name="beanFactory" required="true" hint="Instance of bean factory object" />
		<cfargument name="beanList" required="false" default="" />
		<cfif isSimpleValue(arguments.beanFactory) and len(arguments.beanFactory) eq 0>
			<!--- allow simply passing "" to this function and doing nothing with it --->
			<cfreturn />
		</cfif>
		<cfset application._taffy.externalBeanFactory = arguments.beanFactory />
		<cfset application._taffy.status.externalBeanFactoryUsed = true />
	</cffunction>

	<cffunction name="getBeanFactory" access="private" output="false">
		<cfreturn application._taffy.factory />
	</cffunction>

	<cffunction name="setDefaultMime" access="private" output="false" returntype="void" hint="deprecated-1.1">
		<cfargument name="DefaultMimeType" type="string" required="true" hint="mime time to set as default for this api" />
		<cfset application._taffy.settings.defaultMime = arguments.DefaultMimeType />
	</cffunction>

	<cffunction name="registerMimeType" access="private" output="false" returntype="void" hint="deprecated-1.1">
		<cfargument name="extension" type="string" required="true" hint="ex: json" />
		<cfargument name="mimeType" type="string" required="true" hint="ex: text/json" />
		<cfset application._taffy.settings.mimeExtensions[arguments.extension] = arguments.mimeType />
		<cfset application._taffy.settings.mimeTypes[arguments.mimeType] = arguments.extension />
	</cffunction>

	<cffunction name="newRepresentation" access="public" output="false">
		<cfset var repClass = application._taffy.settings.representationClass />
		<cfif application._taffy.factory.containsBean(repClass)>
			<cfreturn application._taffy.factory.getBean(repClass) />
		<cfelse>
			<cfreturn createObject("component", repClass) />
		</cfif>
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
			<cfset local.decodedCredentials = toString( toBinary( local.EncodedCredentials ) ) />
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
				<cfset arrayAppend(result.functions, func) />
			</cfif>
		</cfloop>
		<cfreturn result />

	</cffunction>

</cfcomponent>
