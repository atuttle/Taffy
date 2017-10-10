<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" />

<!--- <cfdump var="#arguments.config#" abort="true" /> --->
		<cfif structKeyExists(arguments, "tracker")>
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

		<cfif structKeyExists(exception, 'rootcause') && structKeyExists(exception.rootcause, 'cause') && structKeyExists(exception.rootcause.cause, 'message')>
			<cfset msg = exception.rootcause.cause.message />
		<cfelseif structKeyExists(exception, 'cause') && structKeyExists(exception.cause, 'message')>
			<cfset msg = exception.cause.message />
		<cfelseif structKeyExists(exception, 'message')>
			<cfset msg = exception.message />
		<cfelse>
			<cfset msg = variables.message />
		</cfif>

		<cfset var reqHeaders = getHTTPRequestData().headers />
		<cfset var reqBody = getHTTPRequestData().content />
		<!--- on input with content-type "application/json" CF seems to expose it as binary data. Here we convert it back to plain text --->
		<cfif isBinary(reqBody)>
			<cfset reqBody = charsetEncode(reqBody, "UTF-8") />
		</cfif>
		<cfif isJson(reqBody)>
			<cfset reqBody = deserializeJson( reqBody ) />
		</cfif>

		<cfset variables.blhq.notifyService(msg, arguments.exception, { request_body: reqBody, request_headers: reqHeaders }) />
	</cffunction>

</cfcomponent>
