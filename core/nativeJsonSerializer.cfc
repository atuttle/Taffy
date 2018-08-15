<cfcomponent extends="taffy.core.baseSerializer" output="false" hint="Serializer that uses CFML server's json serialization functionality to return json data">

	<cffunction
		name="getAsJson"
		output="false"
		taffy:mime="application/json;text/json"
		taffy:default="true"
		hint="serializes data as JSON">
			<cfreturn rereplace(replace(serializeJSON(variables.data), chr(2), '', 'ALL'), '"\\u0002', '"', 'ALL') />
	</cffunction>

</cfcomponent>
