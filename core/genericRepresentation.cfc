<cfcomponent output="false" hint="a helper class to represent easily serializable data">

	<cfset variables.data = "" />
	<cfset variables.statusCode = 200 />

	<cffunction name="setData" access="public" output="false" returnType="taffy.core.genericRepresentation" hint="setter for the data to be returned">
		<cfargument name="data" required="true" hint="the simple or complex data that you want to return to the api consumer" />
		<cfset variables.data = arguments.data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getAsJson" access="public" output="false" returntype="String" hint="serializes data as JSON">
		<cfreturn serializeJSON(variables.data) />
	</cffunction>

	<cffunction name="withStatus" access="public" output="false" returntype="taffy.core.genericRepresentation" hint="used to set the http response code for the response">
		<cfargument name="statusCode" type="numeric" required="true" hint="eg 200" />
		<cfset variables.statusCode = arguments.statusCode />
		<cfreturn this />
	</cffunction>

</cfcomponent>