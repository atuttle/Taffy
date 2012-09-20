<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfset variables.hothtracker = createObject("component", "Hoth.HothTracker").init(
			createObject("component", arguments.config)
		) />
		<cfreturn this />
	</cffunction>

	<cffunction name="log">
		<cfargument name="exception" />
		<cfset local.result = variables.HothTracker.track(arguments.exception) />
		<cfheader name="X-HOTH-LOGGED-EXCEPTION" value="#local.result#" />
	</cffunction>

</cfcomponent>