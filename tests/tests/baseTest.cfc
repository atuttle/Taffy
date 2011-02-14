<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfif lcase(method) eq "put">
			<cfhttp method="put" url="http://localhost/taffy/tests/index.cfm#arguments.uri#" result="local.result" charset="utf-8">
				<cfif isJson(query)>
					<cfhttpparam type="header" name="Content-Type" value="text/json" />
				<cfelse>
					<cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
				</cfif>
				<cfhttpparam type="body" value="#query#" />
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