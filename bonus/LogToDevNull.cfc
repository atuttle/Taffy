<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" />
		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
	</cffunction>

</cfcomponent>
