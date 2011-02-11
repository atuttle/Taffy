<cfcomponent extends="mxunit.framework.TestCase">

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfhttp method="#arguments.method#" url="http://localhost/taffy/tests/index.cfm#arguments.uri#?#arguments.query#" result="local.result"/>
		<cfreturn local.result />
	</cffunction>

	<cffunction name="getUrl" access="private" output="false">
		<cfargument name="url" type="string" required="true" />
		<cfhttp method="get" url="#arguments.url#" result="local.result" />
		<cfreturn local.result />
	</cffunction>

</cfcomponent>