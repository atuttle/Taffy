<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/{id}">

	<cffunction name="get">
		<cfargument name="id" />
		<cfset local.headers = {}/>
		<cfset local.headers['x-dude'] = "dude!" />
		<cfreturn representationOf(arguments).withStatus(999).withHeaders(local.headers) />
	</cffunction>

	<cffunction name="put">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>

</cfcomponent>