<cfcomponent output="false" hint="a helper class to represent easily serializable data">

	<cfset variables.data = "" />

	<cffunction name="setData" access="public" output="false" returnType="void" hint="setter for the data to be returned">
		<cfargument name="data" type="" required="true" hint="the simple or complex data that you want to return to the api consumer" />
		<cfset variables.data = arguments.data />
	</cffunction>

	<cffunction name="getAsJson" access="public" output="false" returntype="String" hint="serializes data as JSON">
		<cfreturn serializeJSON(variables.data) />
	</cffunction>

</cfcomponent>