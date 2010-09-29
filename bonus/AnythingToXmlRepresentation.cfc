<cfcomponent extends="taffy.core.baseRepresentation">

	<cfset variables.anythingToXml = application.anythingToXml />

	<cffunction name="getAsXML" taffy_mime="application/xml" taffy_default="true">
		<cfreturn variables.anythingToXml.toXml(variables.data) />
	</cffunction>

</cfcomponent>