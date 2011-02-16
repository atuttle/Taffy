<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfargument name="headers" type="struct" default="#structNew()#" />
		
		<cfset var local = structNew() />
		
		<cfif lcase(arguments.method) eq "put" or lcase(arguments.method) eq "post">
			<cfhttp method="#arguments.method#" url="http://localhost/taffy/tests/index.cfm#arguments.uri#" result="local.result" charset="utf-8">
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
			<cfhttp method="#arguments.method#" url="http://localhost/taffy/tests/index.cfm#arguments.uri#?#arguments.query#" result="local.result"/>
		</cfif>
		<cfreturn local.result />
	</cffunction>

	<cffunction name="getUrl" access="private" output="false">
		<cfargument name="url" type="string" required="true" />
		<cfhttp method="get" url="#arguments.url#" result="local.result" />
		<cfreturn local.result />
	</cffunction>

</cfcomponent>