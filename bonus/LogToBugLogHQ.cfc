<cfcomponent implements="taffy.core.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfreturn this />
	</cffunction>

	<cffunction name="log">
		<cfargument name="exception" />
	</cffunction>

</cfcomponent>