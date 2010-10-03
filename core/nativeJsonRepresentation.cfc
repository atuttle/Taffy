<cfcomponent extends="taffy.core.baseRepresentation" output="false" hint="Representation class that uses CFML server's json serialization functionality to return json data">

	<cffunction
		name="getAsJson"
		output="false"
		taffy:mime="application/json"
		taffy:default="true"
		hint="serializes data as JSON">
			<cfreturn serializeJSON(variables.data) />
	</cffunction>

</cfcomponent>