<cfcomponent extends="taffy.core.genericRepresentation">

	<cfset variables.jsonUtil = application.jsonUtil />

	<cffunction name="getAsJson" taffy_mime="application/json" taffy_default="true">
		<cfreturn variables.jsonUtil.serialize(variables.data) />
	</cffunction>

</cfcomponent>