<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" />

<!--- <cfdump var="#arguments.config#" abort="true" /> --->
		<cfif !structKeyExists(arguments, "tracker")>
			<!--- used to inject mocking object for testing --->
			<cfset variables.blhq = arguments.tracker />
		<cfelse>
			<cfset var svc = "bugLog.client.bugLogService" />
			<cfif structKeyExists( arguments.config, "service" )>
				<cfset svc = arguments.config.service />
			</cfif>

			<cfset variables.blhq = createObject("component", svc) />
			<cfset variables.blhq.init(
				argumentCollection=arguments.config
			) />
		</cfif>

		<cfparam name="arguments.config.message" default="Exception trapped in API" />
		<cfset variables.message = arguments.config.message />

		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />

		<cfset var msg = '' />

		<cfif structKeyExists(exception, "message")>
			<cfset msg = exception.message />
		<cfelse>
			<cfset msg = variables.message />
		</cfif>

		<cfset variables.blhq.notifyService(msg, arguments.exception) />
	</cffunction>

</cfcomponent>
