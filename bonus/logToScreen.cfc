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
			TODO: This adapter does not currently support authentication-required email, supplying a specific server, etc.
			That would be a great and relatively easy thing for you to contribute back! :)
		--->
		<cfcontent type="text/html" />
		<cfdump var="#variables#">
		<cfdump var="#arguments#">
		<cfabort>
	</cffunction>

</cfcomponent>