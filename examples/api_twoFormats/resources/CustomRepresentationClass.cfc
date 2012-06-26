<cfcomponent extends="taffy.core.baseRepresentation">

	<cfset variables.jsonUtil = application.jsonUtil />
	<cfset variables.AnythingToXML = application.AnythingToXML />

	<cffunction name="getAsJSON" taffy:mime="application/json" taffy:default="true" output="false">
		<cfreturn variables.jsonUtil.serializeJson(variables.data) />
	</cffunction>

	<cffunction name="getAsXML" taffy:mime="application/xml" output="false">
		<cfreturn variables.AnythingToXML.ToXML(variables.data) />
	</cffunction>

</cfcomponent>