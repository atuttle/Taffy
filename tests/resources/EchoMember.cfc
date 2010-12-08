<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/{id}">

	<cffunction name="get">
		<cfargument name="id" />
		<cfargument name="status" required="false" default="200" />
		<cfset local.headers = {}/>
		<cfset local.headers['x-dude'] = "dude!" />
		<cfreturn representationOf(arguments).withStatus(arguments.status).withHeaders(local.headers) />
	</cffunction>

</cfcomponent>