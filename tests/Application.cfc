<cfcomponent extends="taffy.core.api">

	<cfset this.name = "Taffy_testSuite" />

	<cffunction name="applicationStartEvent">
		<cfset application.init = now() />
	</cffunction>

	<cffunction name="requestStartEvent">
	</cffunction>

	<cffunction name="configureTaffy" output="false">
		<cfset enableDashboard(true)/>
	</cffunction>

</cfcomponent>