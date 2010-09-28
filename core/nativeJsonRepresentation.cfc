<cfcomponent extends="taffy.core.baseRepresentation" output="false" hint="Representation class that uses CFML server's json serialization functionality to return json data">

	<cffunction name="getAsJson" access="public" output="false" returntype="String" taffy_mime="application/json" taffy_default="true" hint="serializes data as JSON">
		<cfreturn serializeJSON(variables.data) />
	</cffunction>

</cfcomponent>