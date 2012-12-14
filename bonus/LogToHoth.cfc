<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" default="#createObject("component", "Hoth.HothTracker")#" />
		<cfset variables.hothtracker = arguments.tracker />
		<cfset variables.hothtracker.init(
			createObject("component", arguments.config)
		) />
		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
		<cfset local.result = variables.HothTracker.track(arguments.exception) />
		<cfheader name="X-HOTH-LOGGED-EXCEPTION" value="#local.result#" />
	</cffunction>

</cfcomponent>