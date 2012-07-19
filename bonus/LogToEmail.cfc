<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfset structAppend( variables, arguments.config, true ) /><!--- copy settings into adapter instance data --->
		<cfreturn this />
	</cffunction>

	<cffunction name="log">
		<cfargument name="exception" />
		<!---
			TODO: this adapter does not currently support authentication-required email, supplying a specific server, etc.
			That would be a great and relatively easy thing for a 3rd party contributor to add! :)
		--->
		<cfmail
			from="#variables.emailFrom#"
			to="#variables.emailTo#"
			subject="#variables.emailSubj#"
			type="#variables.emailType#">
				<cfif variables.emailType eq "text">
Exception Report

Exception Timestamp: <cfoutput>#dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</cfoutput>

<cfdump var="#arguments.exception#" format="text" />
				<cfelse>
					<h2>Exception Report</h2>
					<p><strong>Exception Timestamp:</strong> <cfoutput>#dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</cfoutput></p>
					<cfdump var="#arguments.exception#" />
				</cfif>
		</cfmail>
	</cffunction>

</cfcomponent>