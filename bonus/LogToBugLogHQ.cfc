<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />

		<cfset var svc = "bugLog.client.bugLogService" />
		<cfif structKeyExists( arguments.config, "service" )>
			<cfset svc = arguments.config.service />
		</cfif>

		<cfset variables.blhq = createObject("component", svc) />
		<cfset variables.blhq.init(
			argumentCollection=arguments.config
		) />

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
