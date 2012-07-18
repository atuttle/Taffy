<cfcomponent implements="taffy.core.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<!---
			these are just a copy of the relevant settings from application._taffy.settings
			(which is passed as the config argument here)
		--->
		<cfset variables.emailTo = arguments.config.errorEmailTo />
		<cfset variables.emailFrom = arguments.config.errorEmailFrom />
		<cfset variables.emailSubj = arguments.config.errorEmailSubj />
		<cfset variables.emailType = arguments.config.errorEmailType />

		<cfreturn this />
	</cffunction>

	<cffunction name="log">
		<cfargument name="exception" />
		<!---
			TODO: this adapter does not currently support authentication-required email, supplying a specific server, etc.
			That would be a great and relatively easy thing for a 3rd party contributor to add! :)
		--->
		<cfmail from="#variables.emailFrom#" to="#variables.emailTo#" subject="#variables.emailSubj#" type="#variables.emailType#">
			<h2>Exception Report</h2>
			<p><strong>Exception Timestamp:</strong> <cfoutput>#dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</cfoutput></p>
			<cfif varaibles.emailType eq "text">
				<cfdump var="#arguments.exception#" format="text" />
			<cfelse>
				<cfdump var="#arguments.exception#" />
			</cfif>
		</cfmail>
	</cffunction>

</cfcomponent>