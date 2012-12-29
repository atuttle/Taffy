<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfargument name="headers" type="struct" default="#structNew()#" />
		<cfargument name="basicauth" type="string" default="" />

		<cfset var local = structNew() />

		<cfif lcase(arguments.method) eq "put" or lcase(arguments.method) eq "post">
			<!--- always reload the api before making a request --->
			<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/taffy/tests/index.cfm/dashboard?reload=true" />
			<cfset local.args = {} />
			<cfset local.args.method = arguments.method />
			<cfset local.args.url = "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/taffy/tests/index.cfm#arguments.uri#" />
			<cfset local.args.result = "local.result" />
			<cfset local.args.charset = "utf-8" />
			<cfif len(arguments.basicauth)>
				<cfset local.args.username = listFirst(arguments.basicauth, ":") />
				<cfset local.args.password = listRest(arguments.basicAuth, ":") />
			</cfif>
			<cfhttp attributeCollection="#local.args#">
				<cfif isJson(query)>
					<cfhttpparam type="header" name="Content-Type" value="text/json" />
				<cfelse>
					<cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
				</cfif>
				<cfhttpparam type="body" value="#arguments.query#" />
				
				<!--- Add arbitrary headers to request --->
				<cfloop item="local.header" collection="#arguments.headers#">
					<cfhttpparam type="header" name="#local.header#" value="#arguments.headers[local.header]#" />
				</cfloop>
			</cfhttp>
		<cfelse>
			<cfset local.args = {} />
			<cfset local.args.method = arguments.method />
			<cfset local.args.url = "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/taffy/tests/index.cfm#arguments.uri#?#arguments.query#" />
			<cfset local.args.result = "local.result" />
			<cfset local.args.charset = "utf-8" />
			<cfif len(arguments.basicauth)>
				<cfset local.args.username = listFirst(arguments.basicauth, ":") />
				<cfset local.args.password = listRest(arguments.basicAuth, ":") />
			</cfif>
			<cfhttp attributeCollection="#local.args#">
				<!--- Add arbitrary headers to request --->
				<cfloop item="local.header" collection="#arguments.headers#">
					<cfhttpparam type="header" name="#local.header#" value="#arguments.headers[local.header]#" />
				</cfloop>
			</cfhttp>
		</cfif>
		<cfreturn local.result />
	</cffunction>

	<cffunction name="getUrl" access="private" output="false">
		<cfargument name="url" type="string" required="true" />
		<cfhttp method="get" url="#arguments.url#" result="local.result" />
		<cfreturn local.result />
	</cffunction>

</cfcomponent>