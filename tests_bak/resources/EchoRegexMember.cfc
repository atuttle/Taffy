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


	<cffunction name="setDependency2">
		<cfargument name="dependency2" />
		<cfset this.dependency2 = arguments.dependency2 />
	</cffunction>

</cfcomponent>
