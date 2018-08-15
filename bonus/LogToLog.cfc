<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" hint="unused" default="" />

		<!--- copy settings into adapter instance data --->
		<cfset variables.config = {}>
		<cfset structAppend( variables.config, arguments.config, true ) />

		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
		<cfset var logdump = "">
		<!--- build dump --->
		<cfsavecontent variable="logdump"><cfdump var="#arguments.exception#" format="text"></cfsavecontent>
		<!--- write to log --->
		<cflog file="#variables.config.logfile#" text="#logdump#" type="Error">
	</cffunction>

</cfcomponent>
