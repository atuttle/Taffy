<cfcomponent implements="taffy.bonus.ILogAdapter">

	<cffunction name="init">
		<cfargument name="config" />
		<cfargument name="tracker" hint="unused" default="" />
		<cfreturn this />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
		<cfcontent type="text/html" />
		<cfheader statuscode="500" statustext="Unhandled API Error" />
		<cfdump var="#arguments#" />
		<cfif isDefined('request.debugData')>
			<cfdump var="#request.debugData#" label="debug data" />
		</cfif>
		<cfabort />
	</cffunction>

</cfcomponent>
