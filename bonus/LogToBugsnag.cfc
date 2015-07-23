<!---
	Adapter Path: taffy.bonus.LogToBugsnag
	Configuration Options: (structure)

	variables.framework.exceptionLogAdapterConfig = {
		apiKey = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8",
		appVersion = "1.1.3",
		releaseStage = "production"
	};

	apiKey: The API Key associated with the project
	appVersion: The version number of the application which generated the error
	releaseStage: The release stage that this error occurred in (e.g "development", "staging" or "production")
--->
<cfcomponent implements="taffy.bonus.ILogAdapter">
	<!---
		Initializes this logger
	--->
	<cffunction name="init" hint="I accept a configuration structure to setup and return myself">
		<cfargument name="config" />
		<cfargument name="tracker" />

		<!--- copy settings into adapter instance data --->
		<cfset variables.config = structNew() />
		<cfset structAppend(variables.config, arguments.config, true) />

		<cfreturn this />
	</cffunction>

	<!---
		Logs or notifies the specified exception
	--->
	<cffunction name="saveLog" hint="I log or otherwise notify you of an exception">
		<cfargument name="exception" />

		<!--- Define local variables --->
		<cfset var payload = structNew() />

		<!--- Add Project API key to payload --->
		<cfset payload["apiKey"] = variables.config.apiKey />

		<!--- Add notifier info to payload --->
		<cfset payload["notifier"] = structNew() />
		<cfset payload["notifier"]["name"] = "Taffy" />
		<cfset payload["notifier"]["version"] = "1.0" />
		<cfset payload["notifier"]["url"] = "https://github.com/atuttle/Taffy" />

		<!--- Add exception details to payload --->
		<cfset payload["events"] = arrayNew(1) />
		<cfset payload["events"][1] = structNew() />
		<cfset payload["events"][1]["payloadVersion"] = "2" />
		<cfset payload["events"][1]["exceptions"] = arrayNew(1) />
		<cfset payload["events"][1]["exceptions"][1] = convertException(arguments.exception) />

		<!--- Add application details to payload --->
		<cfset payload["events"][1]["app"] = structNew() />
		<cfset payload["events"][1]["app"]["appVersion"] = variables.config.appVersion />
		<cfset payload["events"][1]["app"]["releaseStage"] = variables.config.releaseStage />

		<!--- Add some metadata to payload --->
		<cfset payload["events"][1]["metaData"] = structNew() />
		<cfset payload["events"][1]["metaData"]["request"] = structNew() />
		<cfset payload["events"][1]["metaData"]["request"]["remoteAddr"] = cgi.remote_addr />
		<cfset payload["events"][1]["metaData"]["request"]["requestMethod"] = cgi.request_method />
		<cfset payload["events"][1]["metaData"]["request"]["requestUrl"] = cgi.request_url />

		<!--- Send log to Bugsnag --->
		<cfhttp url="https://notify.bugsnag.com" method="post">
			<cfhttpparam type="header" name="Content-Type" value="application/json" />
			<cfhttpparam type="body" value="#serializeJSON(payload)#" />
		</cfhttp>
	</cffunction>

	<!---
		Converts the specified exception to be added to the payload
	--->
	<cffunction name="convertException" access="private" returntype="struct" output="false">
		<cfargument name="exception" type="struct" required="true" />

		<!--- Define local variables --->
		<cfset var root = "" />
		<cfset var exceptionElement = structNew() />
		<cfset var tagContextElement = "" />

		<!--- Get the root exception --->
		<cfif structKeyExists(exception, "rootCause")>
			<cfset root = arguments.exception.rootCause />
		<cfelse>
			<cfset root = arguments.exception />
		</cfif>

		<!--- Add type and message to payload --->
		<cfset exceptionElement["errorClass"] = root.type />
		<cfset exceptionElement["message"] = root.message />

		<!--- Build stack trace --->
		<cfset exceptionElement["stacktrace"] = arrayNew(1) />
		<cfloop array="#root.TagContext#" index="tagContextElement">
			<cfset arrayAppend(exceptionElement["stacktrace"], convertTagContextElement(tagContextElement)) />
		</cfloop>

		<cfreturn exceptionElement />
	</cffunction>

	<!---
		Converts the specified Tag Context element to be included in the strack trace array
	---->
	<cffunction name="convertTagContextElement" access="private" returntype="struct" output="false">
		<cfargument name="tagContextElement" type="struct" required="true" />

		<!--- Define local variables --->
		<cfset var stackTraceElement = structNew() />

		<!--- Add stack trace data --->
		<cfset stackTraceElement["file"] = arguments.tagContextElement.template />
		<cfset stackTraceElement["lineNumber"] = arguments.tagContextElement.line />
		<cfset stackTraceElement["columnNumber"] = arguments.tagContextElement.column />
		<cfset stackTraceElement["method"] = "Unknown function" />

		<!--- Add code details --->
		<cfif structKeyExists(arguments.tagContextElement, "codePrintPlain")>
			<cfset stackTraceElement["code"] = convertCodePrint(arguments.tagContextElement.codePrintPlain) />
		</cfif>

		<cfreturn stackTraceElement />
	</cffunction>

	<!---
		Converts the specified code details to be included to the strack trace element
	--->
	<cffunction name="convertCodePrint" access="private" returntype="struct" output="false">
		<cfargument name="codePrintText" type="string" required="true" />

		<!--- Define local variables --->
		<cfset var codeLines = structNew() />
		<cfset var split = listToArray(arguments.codePrintText, chr(10)) />
		<cfset var line = "" />

		<!--- Add code lines --->
		<cfloop array="#split#" index="line">
			<cfset structInsert(codeLines, listFirst(line, ":"), trim(listRest(line, ":"))) />
		</cfloop>

		<cfreturn codeLines />
	</cffunction>
</cfcomponent>