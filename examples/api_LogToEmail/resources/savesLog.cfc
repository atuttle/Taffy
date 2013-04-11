<cfcomponent extends="taffy.core.resource" taffy_uri="/foo">

	<cffunction name="get" access="public" output="false">
		<cfset local.exception = {} />
		<cfset local.exception.message = "testing log to email from resource saveLog()" />
		<cfset saveLog(local.exception) />
		<cfreturn noData().withStatus(200, "Log Saved") />
	</cffunction>

</cfcomponent>