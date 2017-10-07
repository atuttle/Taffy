<cfcomponent>

<cfset this.name = 'Taffy_testSuite' />	<!---uses the same application name as the api Application.cfc for scope sharing --->

<cfset this.mappings["/mxunit"] = expandPath("../testbox/system/compat/")>
<cfset this.mappings["/testbox"] = expandPath("../testbox/")>
<cfset this.mappings["/Hoth"] = expandPath("../Hoth/")>
<cfset this.mappings["/di1"] = expandPath("../di1/")>


<cffunction name="onRequestStart" returnType="void" access="public" output="false">
	<cfif NOT isDefined('application._taffy')>
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />

		<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm" />
	</cfif>
</cffunction>

</cfcomponent>