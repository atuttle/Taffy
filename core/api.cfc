<cfcomponent hint="base class for taffy REST components">

	<!--- you can override these methods in your application.cfc to  --->
	<cfscript>
		function applicationHook(){}	//override this function to run your own code inside onApplicationStart()
		function requestHook(){}		//override this function to run your own code inside onRequestStart()
		function createEndpoints(){}	//override this function to define your endpoints

		/* DO NOT OVERRIDE THIS FUNCTION - SEE applicationHook ABOVE */
		function onApplicationStart(){
			setupFramework();
			defaultMime("json");
			applicationHook();
			return true;
		}
		/* DO NOT OVERRIDE THIS FUNCTION - SEE requestHook ABOVE */
		function onRequestStart(){
			if (structKeyExists(url, "reload") and url.reload){
				setupFramework();
				defaultMime("json");
			}
			requestHook();
			return true;
		}
    </cfscript>


	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- short-circuit logic --->
	<cffunction name="onRequest" output="true" returntype="boolean">
		<cfargument name="targetPage" type="string" required="true" />

		<cfif not structKeyExists(url, "debug")>
			<cfsetting showdebugoutput="false" />
		</cfif>

		<!--- api dashboard --->
		<cfif structKeyExists(url, "dashboard")>
			<cfinclude template="dashboard.cfm" />
			<cfabort>
		</cfif>

		<!--- attempt to find the cfc for the requested uri --->
		<cfset cfcPath = matchURI(cgi.path_info) />

		<!--- uri doesn't map to any known resources --->
		<cfif not len(cfcPath)>
			<h3>Not Implemented</h3>
			<p>TODO: Return some value that explains that the requested URI isn't defined.</p>
			<cfabort>
		</cfif>

		<!--- uri maps to {cfcPath} --->
		<cfset requestArguments = buildRequestArguments()

		yay data will be here!

		<cfreturn true />
	</cffunction>

	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->

	<!--- helper methods --->
	<cffunction name="setupFramework" access="private" output="false" returntype="void">
		<cfset application._taffy = structNew()/>
		<cfset application._taffy.endpoints = {} />
		<cfset application._taffy.settings = {} />
		<cfset application._taffy.settings.defaultMime = "json" />
		<cfset createEndpoints() />
	</cffunction>
	<cffunction name="defaultMime" access="public" output="false" returntype="void">
		<cfargument name="mime" type="string" required="true" hint="mime time to set as default for this api" />
		<cfset _taffy.settings.defaultMime = arguments.mime />
	</cffunction>
	<cffunction name="addEndpoint" access="public" output="false" returntype="taffy.core.api">
		<cfargument name="cfcpath" type="string" required="true" hint="dot.path.to.api" />

		<!--- get the cfc metadata that defines the uri for that cfc --->
		<cfset var uri = getMetaData(createObject("component", arguments.cfcpath)).taffy_uri />
		<cfset var meta = convertURItoRegex(uri) />
		<cfset application._taffy.endpoints[meta.uriRegex] = { cfc = arguments.cfcpath , tokens = meta.tokens } />

		<cfreturn this />
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
			<cfset uriRegex = rereplaceNoCase(uriRegex,"{[^}]+}", "([^\/]+)") />
		</cfloop>

		<!--- require the uri to terminate after specified content --->
		<cfset uriRegex =
				uriRegex & "(\.[^\.\?]+)?"		<!--- anything other than these characters will be considered a mime-type request: / \ ? . --->
						 & "(\?.*)?"			<!--- allow a query string --->
						 & "$" />

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

</cfcomponent>