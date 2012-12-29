<cfcomponent extends="taffy.core.resource" taffy:uri="/echo_regex/{id:\d{5}}">

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

	<cffunction name="post">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>


	<cffunction name="setEchoMember">
		<cfargument name="echoMember" />
		<cfset this.echoMember = arguments.echoMember />
	</cffunction>

</cfcomponent>