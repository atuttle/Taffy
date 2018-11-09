<cfcomponent>

	<cfset this.name = 'Taffy_testSuite' />	<!---uses the same application name as the api Application.cfc for scope sharing --->

	<cfset this.appDirectory = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset this.parentDirectory = reReplace(this.appDirectory, "(.+[/\\])tests[/\\]$", "\1")>
	<cfset this.mappings = structNew()>
	<cfset this.mappings["/mxunit"] = this.parentDirectory & "testbox/system/compat/">
	<cfset this.mappings["/testbox"] = this.parentDirectory & "testbox/">
	<cfset this.mappings["/Hoth"] = this.parentDirectory & "Hoth/">
	<cfset this.mappings["/di1"] = this.parentDirectory & "di1/">
	<cfset this.mappings["/bugLog"] = this.parentDirectory & "BugLogHQ/">

	<cfscript>
		//remove bugLogHQ Application.cfc so we can override datasource definition
		if (fileExists("#this.parentDirectory#/BugLogHQ/Application.cfc")) {
			fileDelete("#this.parentDirectory#/BugLogHQ/Application.cfc");
		}
	</cfscript>

	<cffunction name="onRequestStart" returnType="void" access="public" output="false">
		<cfif NOT isDefined('application._taffy')>
			<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
			<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />
			<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm" />
		</cfif>
	</cffunction>

</cfcomponent>
