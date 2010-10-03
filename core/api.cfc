<cfcomponent hint="Base class for taffy REST application's Application.cfc">

	<cfscript>
		//you can override these methods in your application.cfc
		function applicationStartEvent(){}	//override this function to run your own code inside onApplicationStart()
		function requestStartEvent(){}		//override this function to run your own code inside onRequestStart()
		function configureTaffy(){}			//override this function to set Taffy config settings

		/** onTaffyRequest gives you the opportunity to inspect the request before it is sent to the service.
		  * If you override this function, you MUST either return TRUE or a response object (same class as resources).
		  */
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){return true;}

		/* DO NOT OVERRIDE THIS FUNCTION - SEE applicationStartEvent ABOVE */
		function onApplicationStart(){
			applicationStartEvent();
			setupFramework();
			return true;
		}
		/* DO NOT OVERRIDE THIS FUNCTION - SEE requestStartEvent ABOVE */
		function onRequestStart(){
			//this will probably happen if taffy is sharing an app name with an existing application so that you can use its bean factory
			if (not structKeyExists(application, "_taffy")){
				onApplicationStart();
			}
			//allow reloading
			if (structKeyExists(url, application._taffy.settings.reloadKey) and url[application._taffy.settings.reloadKey] eq application._taffy.settings.reloadPassword){
				setupFramework();
			}
			requestStartEvent();
			return true;
		}
    </cfscript>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- short-circuit logic --->
	<cffunction name="onRequest" output="true" returntype="boolean">
		<cfargument name="targetPage" type="string" required="true" />

		<cfset var _taffyRequest = {} />

		<!--- enable/disable debug output per settings --->
		<cfif not structKeyExists(url, application._taffy.settings.debugKey)>
			<cfsetting showdebugoutput="false" />
		</cfif>

		<!--- display api dashboard if requested --->
		<cfif structKeyExists(url, application._taffy.settings.dashboardKey) and not application._taffy.settings.disableDashboard>
			<cfinclude template="dashboard.cfm" />
			<cfabort>
		</cfif>

		<!--- get request details --->
		<cfset _taffyRequest = parseRequest() />

		<!---
			Now we know everything we need to know to service the request. let's service it!
		--->

		<!--- ...after we let the api developer know all of the request details first... --->
		<cfset _taffyRequest.continue = onTaffyRequest(
			_taffyRequest.verb,
			_taffyRequest.matchDetails.beanName,
			_taffyRequest.requestArguments,
			_taffyRequest.returnMimeExt
		) />

		<cfif not structKeyExists(_taffyRequest, "continue")>
			<!--- developer forgot to return true --->
			<cfthrow
				message="Error in your onTaffyRequest method"
				detail="Your onTaffyRequest method returned no value. Expected: TRUE or a Response Object."
				errorcode="400"
			/>
		</cfif>

		<cfif isObject(_taffyRequest.continue)>
			<!--- inspection complete but request has been aborted by developer; return custom response --->
			<cfset _taffyRequest.result = duplicate(_taffyRequest.continue) />
			<cfset structDelete(_taffyRequest, "continue")/>
		<cfelse>
			<!--- inspection complete and request allowed by developer; send request to service --->

			<!--- if the verb is not implemented, refuse the request --->
			<cfif not structKeyExists(_taffyRequest.matchDetails.methods, _taffyRequest.verb)>
				<cfset throwError(405, "Method Not Allowed") />
			</cfif>
			<!--- returns a representation-object --->
			<cfinvoke
				component="#application._taffy.factory.getBean(_taffyRequest.matchDetails.beanName)#"
				method="#_taffyRequest.verb#"
				argumentcollection="#_taffyRequest.requestArguments#"
				returnvariable="_taffyRequest.result"
			/>
		</cfif>
		<!--- make sure the requested mime type is available --->
		<cfset _taffyRequest.responseMetaData = getMetaData(_taffyRequest.result) />
		<cfif not mimeSupported(_taffyRequest.returnMimeExt)>
			<cfset throwError(400, "Requested MIME type not available") />
		</cfif>

		<!--- serialize the representation into the requested mime type --->
		<cfinvoke
			component="#_taffyRequest.result#"
			method="getAs#_taffyRequest.returnMimeExt#"
			returnvariable="_taffyRequest.resultSerialized"
		/>
		<!--- get status code --->
		<cfinvoke
			component="#_taffyRequest.result#"
			method="getStatus"
			returnvariable="_taffyRequest.resultStatus"
		/>
		<!--- get custom headers --->
		<cfinvoke
			component="#_taffyRequest.result#"
			method="getHeaders"
			returnvariable="_taffyRequest.resultHeaders"
		/>

		<cfsetting enablecfoutputonly="true" />
		<cfcontent reset="true" type="#application._taffy.settings.mimeExtensions[_taffyRequest.returnMimeExt]#" />
		<cfheader statuscode="#_taffyRequest.resultStatus#"/>
		<cfif not structIsEmpty(_taffyRequest.resultHeaders)>
			<cfloop collection="#_taffyRequest.resultHeaders#" item="_taffyRequest.headerName">
				<cfheader name="#_taffyRequest.headerName#" value="#_taffyRequest.resultHeaders[_taffyRequest.headerName]#" />
			</cfloop>
			<cfset structDelete(_taffyRequest, "headerName")/>
		</cfif>
		<cfif _taffyRequest.resultSerialized neq ('"' & '"')>
			<cfoutput>#_taffyRequest.resultSerialized#</cfoutput>
		</cfif>

		<cfif structKeyExists(url, application._taffy.settings.debugKey)>
			<cfoutput><h3>Request Details:</h3><cfdump var="#_taffyRequest#"></cfoutput>
		</cfif>

		<cfreturn true />
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- internal methods --->
	<cffunction name="setupFramework" access="private" output="false" returntype="void">
		<cfset application._taffy = structNew() />
		<cfset application._taffy.endpoints = {} />
		<!--- default settings --->
		<cfset application._taffy.settings = {
			defaultMime = "",
			debugKey = "debug",
			reloadKey = "reload",
			reloadPassword = "true",
			defaultRepresentationClass = "taffy.core.nativeJsonRepresentation",
			dashboardKey = "dashboard",
			disableDashboard = false
		} />
		<!--- allow setting overrides --->
		<cfset configureTaffy()/>
		<!--- automatically introspect mime types from cfc metadata of default representation class --->
		<cfset inspectMimeTypes(application._taffy.settings.defaultRepresentationClass) />
		<!--- if resources folder exists, use internal bean factory --->
		<cfset _taffyRequest.resourcePath = getDirectoryFromPath(getBaseTemplatePath()) & '/resources' />
		<cfif directoryExists(_taffyRequest.resourcePath)>
			<!--- setup internal bean factory --->
			<cfset application._taffy.factory = createObject("component", "taffy.core.factory").init() />
			<cfset application._taffy.factory.loadBeansFromPath(_taffyRequest.resourcePath) />
			<cfset application._taffy.beanList = application._taffy.factory.getBeanList() />
			<cfset cacheBeanMetaData(application._taffy.factory, application._taffy.beanList) />
			<!---
				if both an external bean factory and the internal factory are in use (because of /resources folder),
				resolve dependencies for each bean of internal factory with the external factory's resources
			--->
			<cfif structKeyExists(application._taffy, "externalBeanFactory")>
				<cfset resolveDependencies() />
			</cfif>
		<cfelseif structKeyExists(application._taffy, "externalBeanFactory")>
			<!--- only using external factory, so create a pointer to it --->
			<cfset application._taffy.factory = application._taffy.externalBeanFactory />
		</cfif>
	</cffunction>
	<cffunction name="parseRequest" access="private" output="false" returnType="struct">
		<cfset var requestObj = {} />
		<cfset var tmp = 0 />

		<!--- attempt to find the cfc for the requested uri --->
		<cfset requestObj.matchingRegex = matchURI(cgi.path_info) />

		<!--- uri doesn't map to any known resources --->
		<cfif not len(requestObj.matchingRegex)>
			<cfset throwError(404, "Not Found") />
		</cfif>

		<!--- get the cfc name and token array for the matching regex --->
		<cfset requestObj.matchDetails = application._taffy.endpoints[requestObj.matchingRegex] />

		<!--- which verb is requested? --->
		<cfset requestObj.verb = cgi.request_method />

		<cfif ucase(requestObj.verb) eq "PUT">
			<cfset requestObj.queryString = getPutParameters() />
		<cfelse>
			<cfset requestObj.queryString = cgi.query_string />
		</cfif>

		<!--- build the argumentCollection to pass to the cfc --->
		<cfset requestObj.requestArguments = buildRequestArguments(
			requestObj.matchingRegex,
			requestObj.matchDetails.tokens,
			cgi.path_info,
			requestObj.queryString
		) />
		<!--- also capture form POST data (higher priority that url variables of same name) --->
		<cfset structAppend(requestObj.requestArguments, form) />

		<!--- use requested mime type or the default --->
		<cfset requestObj.returnMimeExt = "" />
		<cfif structKeyExists(requestObj.requestArguments, "_taffy_mime")>
			<cfset requestObj.returnMimeExt = requestObj.requestArguments["_taffy_mime"] />
			<cfset structDelete(requestObj.requestArguments, "_taffy_mime") />
		<cfelse>
			<cfif structKeyExists(cgi, "http_accept") and len(cgi.http_accept)>
				<cfloop list="#cgi.HTTP_ACCEPT#" index="tmp">
					<!--- deal with that q=0 stuff (just ignore it) --->
					<cfif listLen(tmp, ";") gt 1>
						<cfset tmp = listFirst(tmp, ";") />
					</cfif>
					<cfif structKeyExists(application._taffy.settings.mimeTypes, tmp)>
						<cfset requestObj.returnMimeExt = application._taffy.settings.mimeTypes[tmp] />
					<cfelse>
						<cfset requestObj.returnMimeExt = application._taffy.settings.defaultMime />
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
		<cfreturn requestObj />
	</cffunction>
	<cffunction name="convertURItoRegex" access="private" output="false">
		<cfargument name="uri" type="string" required="true" hint="wants the uri mapping defined by the cfc endpoint" />
		<cfset var local = StructNew() />
		<cfset local.almostTokens = rematch("{([^}]+)}", arguments.uri)/>
		<cfset local.returnData = StructNew() />
		<cfset local.returnData.tokens = ArrayNew(1) />

		<!--- extract token names and values from requested uri --->
		<cfset local.uriRegex = arguments.uri />
		<cfloop array="#local.almostTokens#" index="local.token">
			<cfset arrayAppend(local.returnData.tokens, replaceList(local.token, "{,}", ",")) />
			<cfset local.uriRegex = rereplaceNoCase(local.uriRegex,"{[^}]+}", "([^\/\.]+)") />
		</cfloop>

		<!--- require the uri to terminate after specified content --->
		<cfset local.uriRegex &=
							  "(\.[^\.\?]+)?"	<!--- anything other than these characters will be considered a mime-type request: / \ ? . --->
							  & "$" />			<!--- terminate the uri (query string not included in cgi.path_info, does not need to be accounted for here) --->

		<cfset local.returnData.uriRegex = local.uriRegex />

		<cfreturn local.returnData />
	</cffunction>
	<cffunction name="matchURI" access="private" output="false" returnType="string">
		<cfargument name="requestedURI" type="string" required="true" hint="probably just pass in cgi.path_info" />
		<cfset var endpoint = '' />
		<cfloop collection="#application._taffy.endpoints#" item="endpoint">
			<cfset attempt = reMatchNoCase(endpoint, arguments.requestedURI) />
			<cfif arrayLen(attempt) gt 0>
				<!--- found our mapping --->
				<cfreturn endpoint />
			</cfif>
		</cfloop>
		<!--- nothing found --->
		<cfreturn "" />
	</cffunction>
	<cffunction name="getPutParameters" access="private" output="false" returntype="String" hint="Gets PUT data into a string similar to cgi.query_string, which CF doesn't do automatically">
		<!--- Special thanks to Jason Dean (@JasonPDean) and Ray Camden (@ColdFusionJedi) who helped me figure out how to do this --->
		<cfreturn getHTTPRequestData().content />
	</cffunction>
	<cffunction name="buildRequestArguments" access="private" output="false" returnType="struct">
		<cfargument name="regex" type="string" required="true" hint="regex that describes the request (including uri and query string parameters)" />
		<cfargument name="tokenNamesArray" type="array" required="true" hint="array of token names associated with the matched uri" />
		<cfargument name="uri" type="string" required="true" hint="the requested uri" />
		<cfargument name="queryString" type="string" required="true" hint="any query string parameters included in the request" />
		<cfset var local = StructNew() />
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
		<!--- also parse query string parameters into key-value pairs (support both json packet and query string as input) --->
		<cfif isJSON(arguments.queryString)>
			<cfset local.tmp = deserializeJSON(arguments.queryString) />
			<cfset structAppend(local.returnData, local.tmp) />
		<cfelse>
			<cfloop list="#arguments.queryString#" delimiters="&" index="local.t">
				<cfset local.returnData[listFirst(local.t,'=')] = urlDecode(listLast(local.t,'=')) />
			</cfloop>
		</cfif>
		<!--- if a mime type is requested as part of the url ("whatever.json"), then extract that so taffy can use it --->
		<cfif local.numTokenValues gt local.numTokenNames>
			<cfset local.mime = local.tokenValues[local.numTokenValues] /><!--- the last token represents ".json"/etc --->
			<cfset local.mimeLen = len(local.mime) />
			<cfset local.returnData["_taffy_mime"] = right(local.mime, local.mimeLen - 1) />
		</cfif>
		<!--- return --->
		<cfreturn returnData />
	</cffunction>
	<cffunction name="throwError" access="private" output="false" returntype="void">
		<cfargument name="statusCode" type="numeric" default="500" />
		<cfargument name="msg" type="string" required="true" hint="message to return to api consumer" />
		<cfcontent reset="true" />
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
			<cfif structKeyExists(local.cfcMetadata, "taffy_uri")>
				<cfset local.uri = local.cfcMetadata["taffy_uri"] />
			<cfelseif structKeyExists(local.cfcMetadata, "taffy:uri")>
				<cfset local.uri = local.cfcMetadata["taffy:uri"] />
			</cfif>
			<cfset local.metaInfo = convertURItoRegex(local.uri) />
			<cfif structKeyExists(application._taffy.endpoints, local.metaInfo.uriRegex)>
				<cfthrow
					message="Duplicate URI scheme detected. All URIs must be unique (excluding tokens)."
					detail="The URI for `#beanName#` conflicts with the existing URI definition of `#application._taffy.endpoints[metaInfo.uriRegex].beanName#`"
					errorcode="taffy.resources.DuplicateUriPattern"
				/>
			</cfif>
			<cfset application._taffy.endpoints[local.metaInfo.uriRegex] = { beanName = local.beanName, tokens = local.metaInfo.tokens, methods = structNew(), srcURI = local.uri } />
			<cfloop array="#local.cfcMetadata.functions#" index="local.f">
				<cfif local.f.name eq "get" or local.f.name eq "post" or local.f.name eq "put" or local.f.name eq "delete" or local.f.name eq "head">
					<cfset application._taffy.endpoints[local.metaInfo.uriRegex].methods[local.f.name] = true />
				</cfif>
			</cfloop>
		</cfloop>
	</cffunction>
	<cffunction name="resolveDependencies" access="private" output="false" returnType="void">
		<cfset var local = StructNew() />
		<cfloop list="#structKeyList(application._taffy.endpoints)#" index="local.endpoint">
			<cfloop list="#structKeyList(application._taffy.endpoints[endpoint].methods)#" index="local.method">
				<cfif left(local.method, 3) eq "set">
					<!--- we've found a dependency, try to resolve it --->
					<cfset local.beanName = right(local.method, len(local.method) - 3) />
					<cfif application._taffy.externalBeanFactory.containsBean(local.beanName)>
						<cfset local.bean = application._taffy.factory.getBean(application._taffy.endpoints[local.endpoint].beanName) />
						<cfset local.dependency = application._taffy.externalBeanFactory.getBean(local.beanName) />
						<cfset evaluate("local.bean.#method#(local.dependency)") />
					</cfif>
				</cfif>
			</cfloop>
		</cfloop>
	</cffunction>
	<cffunction name="getBeanListFromExternalFactory" output="false" access="private" returntype="String">
		<cfset var beanFactoryMeta = getMetadata(application._taffy.externalBeanFactory) />
		<cfif lcase(left(beanFactoryMeta.name, 10)) eq "coldspring">
			<cfreturn getBeanListFromColdSpring() />
		<!---
			What other popular bean factories should be supported?
			They would be added here, if they don't support getBeanList out of the box.
			TODO: Add support for DI/1 when it is released
		 --->
		</cfif>
		<cfreturn "" />
	</cffunction>
	<cffunction name="getBeanListFromColdSpring" access="private" output="false" returntype="string">
		<cfset var local = StructNew() />
		<cfset local.beans = application._taffy.externalBeanFactory.getBeanDefinitionList() />
		<cfloop collection="#local.beans#" item="local.beanName">
			<cfif local.beans[local.beanName].instanceOf('taffy.core.resource')>
				<cfset local.beanList = listAppend(local.beanList, local.beanName) />
			</cfif>
		</cfloop>
		<cfreturn local.beanList />
	</cffunction>
	<cffunction name="inspectMimeTypes" access="private" output="false" returntype="void">
		<cfargument name="customClassDotPath" type="string" required="true" hint="dot-notation path of representation class" />
		<cfset _recurse_inspectMimeTypes(getComponentMetadata(arguments.customClassDotPath)) />
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
		<cfreturn false />
	</cffunction>
	<cffunction name="reFindNoSuck" output="false" access="private">
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

	<!--- helper methods --->
	<cffunction name="setBeanFactory" access="public" output="false" returntype="void">
		<cfargument name="beanFactory" required="true" hint="Instance of bean factory object" />
		<cfargument name="beanList" required="false" default="" />
		<cfset application._taffy.externalBeanFactory = arguments.beanFactory />
		<cfif len(arguments.beanList) eq 0>
			<cfset arguments.beanList = getBeanListFromExternalFactory() />
		</cfif>
		<cfset cacheBeanMetaData(application._taffy.externalBeanFactory, arguments.beanList) />
	</cffunction>
	<cffunction name="setDefaultMime" access="public" output="false" returntype="void">
		<cfargument name="DefaultMimeType" type="string" required="true" hint="mime time to set as default for this api" />
		<cfset application._taffy.settings.defaultMime = arguments.DefaultMimeType />
	</cffunction>
	<cffunction name="setDebugKey" access="public" output="false" returnType="void">
		<cfargument name="keyName" type="string" required="true" hint="url parameter you want to use to enable ColdFusion debug output" />
		<cfset application._taffy.settings.debugKey = arguments.keyName />
	</cffunction>
	<cffunction name="setDashboardKey" access="public" output="false" returnType="void">
		<cfargument name="keyName" type="string" required="true" hint="url parameter you want to use to show the Taffy dashboard" />
		<cfset application._taffy.settings.dashboardKey = arguments.keyName />
	</cffunction>
	<cffunction name="enableDashboard" access="public" output="false" returntype="void" hint="Enable and disable usage of the dashboard via the dashboard key existing as a url parameter">
		<cfargument name="enabled" type="boolean" required="true" />
		<cfset application._taffy.settings.disableDashboard = !(arguments.enabled) />
	</cffunction>
	<cffunction name="setReloadKey" access="public" output="false" returnType="void">
		<cfargument name="keyName" type="string" required="true" hint="url parameter you want to use to reload Taffy (clear cache, reset settings)" />
		<cfset application._taffy.settings.reloadKey = arguments.keyName />
	</cffunction>
	<cffunction name="setReloadPassword" access="public" output="false" returnType="void">
		<cfargument name="password" type="string" required="true" hint="value required for the reload key to initiate a reload. if it doesn't match, then the framework will not reload." />
		<cfset application._taffy.settings.reloadPassword = arguments.password />
	</cffunction>
	<cffunction name="registerMimeType" access="public" output="false" returntype="void">
		<cfargument name="extension" type="string" required="true" hint="ex: json" />
		<cfargument name="mimeType" type="string" required="true" hint="ex: text/json" />
		<cfset application._taffy.settings.mimeExtensions[arguments.extension] = arguments.mimeType />
		<cfset application._taffy.settings.mimeTypes[arguments.mimeType] = arguments.extension />
	</cffunction>
	<cffunction name="setDefaultRepresentationClass" access="public" output="false" returnType="void" hint="Override the global default representation object with a custom class">
		<cfargument name="customClassDotPath" type="string" required="true" hint="Dot-notation path to your custom class to use as the default" />
		<cfset application._taffy.settings.defaultRepresentationClass = arguments.customClassDotPath />
	</cffunction>

</cfcomponent>