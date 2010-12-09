<cfcomponent output="false" hint="a helper class to represent easily serializable data">

	<cfset variables.data = "" />
	<cfset variables.statusCode = 200 />
	<cfset variables.miscHeaders = StructNew() />

	<cffunction name="setData" access="public" output="false" hint="setter for the data to be returned">
		<cfargument name="data" required="true" hint="the simple or complex data that you want to return to the api consumer" />
		<cfset variables.data = arguments.data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getData" access="public" output="false" hint="mostly for testability, returns the native data embedded in the representation instance">
		<cfreturn variables.data />
	</cffunction>

	<cffunction name="noData" access="public" output="false" hint="returns empty representation instance">
		<cfreturn this />
	</cffunction>

	<cffunction name="withStatus" access="public" output="false" hint="used to set the http response code for the response">
		<cfargument name="statusCode" type="numeric" required="true" hint="eg 200" />
		<cfset variables.statusCode = arguments.statusCode />
		<cfreturn this />
	</cffunction>

	<cffunction name="getStatus" access="public" output="false" returnType="numeric">
		<cfreturn variables.statusCode />
	</cffunction>

	<cffunction name="withHeaders" access="public" output="false" hint="used to set custom headers for the response">
		<cfargument name="headerStruct" type="struct" required="true" />
		<cfset variables.miscHeaders = arguments.headerStruct />
		<cfreturn this />
	</cffunction>

	<cffunction name="getHeaders" access="public" output="false" returntype="Struct">
		<cfreturn variables.miscHeaders />
	</cffunction>

</cfcomponent>