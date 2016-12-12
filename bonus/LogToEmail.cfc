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

		<cfset var local = StructNew() />

		<cfset variables.config = removeEmailPrefix(variables.config)>

		<!--- to conform to the cfmail attribute name and be backward compatible with emailSubj --->
		<cfset variables.config.subject = variables.config.subj>

		<cfset local.attributeCollection = variables.config>

		<cfmail attributeCollection="#local.attributeCollection#">
			<cfif variables.config.type eq "text">
				Exception Report

				Exception Timestamp: <cfoutput>#dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</cfoutput>

				<cfdump var="#arguments.exception#" format="text" />
				<cfif isDefined('request.debugData')>
					<cfdump var="#request.debugData#" label="debug data" format="text"/>
				</cfif>
			<cfelse>
				<h2>Exception Report</h2>
				<p><strong>Exception Timestamp:</strong> <cfoutput>#dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</cfoutput></p>
				<cfdump var="#arguments.exception#" />
				<cfif isDefined('request.debugData')>
					<cfdump var="#request.debugData#" label="debug data" />
				</cfif>
			</cfif>
		</cfmail>
	</cffunction>

	<cffunction name="removeEmailPrefix" output="false" access="private" returntype="struct" hint="removes all email prefix from the config attributes">
		<cfargument name="configAttributes" required="true" type="struct" />

		<cfset var configAttributeName="" />
		<cfset var configAttributeValue = "" />
		<cfset var newConfig = {} />
		<cfloop collection="#arguments.configAttributes#" item="configAttributeName">
			<cfset configAttributeNameWithoutEmailPrefix = replaceNoCase(configAttributeName, "email", "", "one") />
			<cfset newConfig[configAttributeNameWithoutEmailPrefix] = arguments.configAttributes[configAttributeName] />
		</cfloop>

		<cfreturn newConfig />
	</cffunction>

</cfcomponent>
