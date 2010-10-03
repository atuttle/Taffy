<cfcomponent extends="taffy.core.baseRepresentation">

	<cfset variables.anythingToXml = application.anythingToXml />

	<cffunction
		name="getAsXML"
		output="false"
		taffy:mime="application/xml"
		taffy:default="true">
			<cfreturn variables.anythingToXml.toXml(variables.data) />
	</cffunction>

</cfcomponent>