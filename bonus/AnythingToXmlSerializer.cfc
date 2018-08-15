<cfcomponent extends="taffy.core.baseSerializer">

	<!--- remove because causing tests to fail 
	<cfset variables.anythingToXml = application.anythingToXml />
	--->

	<cffunction
		name="getAsXML"
		output="false"
		taffy:mime="application/xml"
		taffy:default="true">
			<cfreturn application.anythingToXml.toXml(variables.data) />
	</cffunction>

</cfcomponent>
