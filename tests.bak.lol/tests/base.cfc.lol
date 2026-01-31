<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfargument name="headers" type="struct" default="#structNew()#" />
		<cfargument name="basicauth" type="string" default="" />

		<cfset var local = structNew() />
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />

		<cfset local.args = {} />
		<cfset local.args.method = arguments.method />
		<cfset local.args.redirect = false />
		<cfset local.args.result = "local.result" />
		<cfset local.args.charset = "utf-8" />
		<cfif len(arguments.basicauth)>
			<cfset local.args.username = listFirst(arguments.basicauth, ":") />
			<cfset local.args.password = listRest(arguments.basicAuth, ":") />
		</cfif>
		<cfset local.args.url = "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm#arguments.uri#" />

		<cfif lcase(arguments.method) eq "put" or lcase(arguments.method) eq "post">
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
			<cfif find('?',local.args.url)>
				<cfset local.args.url = '#local.args.url##arguments.query#' />
			<cfelse>
				<cfset local.args.url = '#local.args.url#?#arguments.query#' />
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

	<cffunction name="checkIfOneSkippedRessourceContainsExpectedException" access="private" output="false" returntype="boolean">
		<cfargument name="exceptionAttributeName" type="string" required="true" />
		<cfargument name="expectedValue" type="string" required="true" />
		<cfset var skippedRessource = "">
		<cfset var expectedExceptionAttributeValueFound = 0>

		<cfloop array="#application._taffy.status.skippedResources#" index="skippedRessource">
			<cfset expectedExceptionAttributeValueFound = structKeyExists(skippedRessource.exception, arguments.exceptionAttributeName) and skippedRessource.exception[arguments.exceptionAttributeName] is arguments.expectedValue>
			<cfif expectedExceptionAttributeValueFound>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfreturn expectedExceptionAttributeValueFound>
	</cffunction>

	<cffunction name="reloadFramework" access="private">
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />
		<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm?#application._taffy.settings.reloadkey#=#application._taffy.settings.reloadPassword#" />
	</cffunction>

</cfcomponent>
