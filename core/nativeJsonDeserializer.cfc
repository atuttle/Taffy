<cfcomponent extends="taffy.core.baseDeserializer">

	<cffunction name="getFromJson" output="false" taffy:mime="application/json,text/json" hint="get data from json">
		<cfargument name="body" hint="the textual request body" />
		<cfset var data = 0 />
		<cfset var response = {} />

		<cfif not isJson(arguments.body)>
			<cfset throwError(msg="Input JSON is not well formed", statusCode="400") />
		</cfif>
		<cfset data = deserializeJSON(arguments.body) />
		<cfif not isStruct(data)>
			<cfset response['_body'] = data />
		<cfelse>
			<cfset response = data />
		</cfif>

		<cfreturn response />
	</cffunction>

</cfcomponent>
