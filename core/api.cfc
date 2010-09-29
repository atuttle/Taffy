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
		<cfset _taffyRequest.mimeFound = false />
		<cfloop from="1" to="#arrayLen(_taffyRequest.responseMetaData.functions)#" index="_taffyRequest.fnI">
			<cfif lcase(_taffyRequest.responseMetaData.functions[_taffyRequest.fnI].name) eq "getas#_taffyRequest.returnMimeExt#">
				<cfset _taffyRequest.mimeFound = true />
				<cfbreak />
			</cfif>
		</cfloop>
		<cfset structDelete(_taffyRequest, "responseMetaData") />
		<cfset structDelete(_taffyRequest, "fnI") />
		<cfif not _taffyRequest.mimeFound>
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
		<cfif _taffyRequest.resultSerialized neq '""""'>
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
			defaultRepresentationClass = "taffy.core.genericRepresentation",
			dashboardKey = "dashboard",
			disableDashboard = false
		} />
		<!--- allow setting overrides --->
		<cfset configureTaffy()/>
		<!--- automatically introspect mime types from cfc metadata of default representation class --->
		<cfset inspectMimeTypes(application._taffy.settings.defaultRepresentationClass) />
		<!--- check to make sure default mime is supported --->
		<cfif not mimeSupported(application._taffy.settings.defaultMime)>
			<cfthrow message="Default mime type does not appear to be supported" detail="The default mime type, #ucase(application._taffy.settings.defaultMime)#, does not have a corresponding serialization function 'getAs#application._taffy.settings.defaultMime#' in the default representation class: #application._taffy.settings.defaultRepresentationClass#." errorcode="taffy.mime.notsupported" />
		</cfif>
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

		<cfset var almostTokens = rematch("{([^}]+)}", arguments.uri)/>
		<cfset var token = '' />
		<cfset var returnData = { tokens = [] } />

		<!--- extract token names and values from requested uri --->
		<cfset var uriRegex = arguments.uri />
		<cfloop array="#almostTokens#" index="token">
			<cfset arrayAppend(returnData.tokens, replaceList(token, "{,}", ",")) />
			<cfset uriRegex = rereplaceNoCase(uriRegex,"{[^}]+}", "([^\/\.]+)") />
		</cfloop>

		<!--- require the uri to terminate after specified content --->
		<cfset uriRegex &=
						"(\.[^\.\?]+)?"		<!--- anything other than these characters will be considered a mime-type request: / \ ? . --->
						& "$" />			<!--- terminate the uri (query string not included in cgi.path_info, does not need to be accounted for here) --->

		<cfset returnData.uriRegex = uriRegex />

		<cfreturn returnData />
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
		<cfset var returnData = {} /><!--- this will be used as an argumentCollection for the method that ultimately gets called --->
		<cfset var t = '' />
		<cfset var i = '' />
		<cfset var mime = '' />
		<cfset var mimeLen = '' />
		<!--- parse path_info data into key-value pairs --->
		<cfset var tokenValues = reFindNoSuck(arguments.regex, arguments.uri) />
		<cfset var numTokenValues = arrayLen(tokenValues) />
		<cfset var numTokenNames = arrayLen(arguments.tokenNamesArray) />
		<cfif numTokenNames gt 0>
			<cfloop from="1" to="#numTokenNames#" index="t">
				<cfset returnData[arguments.tokenNamesArray[t]] = tokenValues[t] />
			</cfloop>
		</cfif>
		<!--- also parse query string parameters into key-value pairs --->
		<cfloop list="#arguments.queryString#" delimiters="&" index="t">
			<cfset returnData[listFirst(t,'=')] = urlDecode(listLast(t,'=')) />
		</cfloop>
		<!--- if a mime type is requested as part of the url ("whatever.json"), then extract that so taffy can use it --->
		<cfif numTokenValues gt numTokenNames>
			<cfset mime = tokenValues[numTokenValues] /><!--- the last token represents ".json"/etc --->
			<cfset mimeLen = len(mime) />
			<cfset returnData["_taffy_mime"] = right(mime, mimeLen - 1) />
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
		<cfset var beanName = '' />
		<cfset var metaInfo = '' />
		<cfset var cfcMetadata = '' />
		<cfset var f = '' />
		<cfloop list="#arguments.beanList#" index="beanName">
			<!--- get the cfc metadata that defines the uri for that cfc --->
			<cfset cfcMetadata = getMetaData(arguments.factory.getBean(beanName)) />
			<cfset metaInfo = convertURItoRegex(cfcMetadata.taffy_uri) />
			<cfif structKeyExists(application._taffy.endpoints, metaInfo.uriRegex)>
				<cfthrow
					message="Duplicate URI scheme detected. All URIs must be unique (excluding tokens)."
					detail="The URI for `#beanName#` conflicts with the existing URI definition of `#application._taffy.endpoints[metaInfo.uriRegex].beanName#`"
					errorcode="taffy.resources.DuplicateUriPattern"
				/>
			</cfif>
			<cfset application._taffy.endpoints[metaInfo.uriRegex] = { beanName = beanName, tokens = metaInfo.tokens, methods = structNew() } />
			<cfloop array="#cfcMetadata.functions#" index="f">
				<cfif f.name eq "get" or f.name eq "post" or f.name eq "put" or f.name eq "delete" or f.name eq "head">
					<cfset application._taffy.endpoints[metaInfo.uriRegex].methods[f.name] = true />
				</cfif>
			</cfloop>
		</cfloop>
	</cffunction>
	<cffunction name="resolveDependencies" access="private" output="false" returnType="void">
		<cfset var endpoint = '' />
		<cfset var method = '' />
		<cfset var beanName = '' />
		<cfset var bean = '' />
		<cfset var dependency = '' />
		<cfloop list="#structKeyList(application._taffy.endpoints)#" index="endpoint">
			<cfloop list="#structKeyList(application._taffy.endpoints[endpoint].methods)#" index="method">
				<cfif left(method, 3) eq "set">
					<!--- we've found a dependency, try to resolve it --->
					<cfset beanName = right(method, len(method) - 3) />
					<cfif application._taffy.externalBeanFactory.containsBean(beanName)>
						<cfset bean = application._taffy.factory.getBean(application._taffy.endpoints[endpoint].beanName) />
						<cfset dependency = application._taffy.externalBeanFactory.getBean(beanName) />
						<cfset evaluate("bean.#method#(dependency)") />
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
		 --->
		</cfif>
		<cfreturn "" />
	</cffunction>
	<cffunction name="getBeanListFromColdSpring" access="private" output="false" returntype="string">
		<cfset var beans = application._taffy.externalBeanFactory.getBeanDefinitionList() />
		<cfset var beanList = "" />
		<cfset var beanName = "" />
		<cfloop collection="#beans#" item="beanName">
			<cfif beans[beanName].instanceOf('taffy.core.resource')>
				<cfset beanList = listAppend(beanList, beanName) />
			</cfif>
		</cfloop>
		<cfreturn beanList />
	</cffunction>
	<cffunction name="inspectMimeTypes" access="private" output="false" returntype="void">
		<cfargument name="customClassDotPath" type="string" required="true" hint="dot-notation path of representation class" />
		<cfset var tmp = getComponentMetadata(arguments.customClassDotPath).functions />
		<cfset var f = 0 />
		<cfset var ext = '' />
		<cfloop from="1" to="#arrayLen(tmp)#" index="f">
			<!--- for every function whose name starts with "getAs" *and* has a taffy_mime metadata attribute, register the mime type --->
			<cfif ucase(left(tmp[f].name, 5)) eq "GETAS" and structKeyExists(tmp[f], "taffy_mime")>
				<cfset ext = lcase(right(tmp[f].name, len(tmp[f].name)-5)) />
				<cfset registerMimeType(ext, lcase(tmp[f].taffy_mime)) />
				<!--- check for taffy_default metadata to set the current mime as the default --->
				<cfif structKeyExists(tmp[f], "taffy_default") and tmp[f].taffy_default>
					<cfset setDefaultMime(ext) />
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>
	<cffunction name="mimeSupported" access="private" output="false" returntype="boolean">
		<cfargument name="mime" type="string" required="true" />
		<cfset var metadata = getComponentMetadata(application._taffy.settings.defaultRepresentationClass) />
		<cfset var i = 0 />
		<cfloop from="1" to="#arrayLen(metadata.functions)#" index="i">
			<cfif lcase(metadata.functions[i].name) eq "getas#lcase(arguments.mime)#">
				<cfreturn true />
			</cfif>
		</cfloop>
		<cfreturn false />
	</cffunction>
	<cffunction name="reFindNoSuck" output="false" access="private">
		<cfargument name="pattern" required="true" type="string" />
		<cfargument name="data" required="true" type="string" />
		<cfargument name="startPos" required="false" default="1" />
		<cfscript>
			var sucky = '';
			var i = 0;
			var awesome = [];
			var matchBody = '';
			sucky = refindNoCase(pattern, data, startPos, true);
			if (not isArray(sucky.len) or arrayLen(sucky.len) eq 0){return arrayNew(1);} //handle no match at all
			for (i=1; i<= arrayLen(sucky.len); i++){
				//if there's a match with pos 0 & length 0, that means the mime type was not specified
				if (sucky.len[i] gt 0 && sucky.pos[i] gt 0){
					//don't include the group that matches the entire pattern
					matchBody = mid( data, sucky.pos[i], sucky.len[i]);
					if (matchBody neq arguments.data){
						arrayAppend( awesome, matchBody );
					}
				}
			}
			return awesome;
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