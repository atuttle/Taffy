<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" hint="unused" default="" />

		<!--- copy settings into adapter instance data --->
		<cfset structAppend( variables, arguments.config, true ) />

		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
		<!---
			don't do anything..
		--->

	</cffunction>

</cfcomponent>