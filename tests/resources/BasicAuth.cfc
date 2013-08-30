<cfcomponent extends="taffy.core.resource" taffy:uri="/basicauth">

	<cffunction name="get">
		<cfargument name="username" default="" />
		<cfargument name="password" default="" />
		<cfreturn representationOf(arguments) />
	</cffunction>

</cfcomponent>