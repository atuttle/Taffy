<cfcomponent extends="taffy.core.resource" taffy:uri="/echo_alias/{id}, /echo_alias" hint="I have multiple uris">

	<cffunction name="get">
		<cfargument name="id" default="0" />
		<cfset local.res = {} />
		<cfset local.res.id = arguments.id />

		<cfreturn representationOf(local.res) />
	</cffunction>

	<cffunction name="put">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>

	<cffunction name="post">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>

</cfcomponent>
