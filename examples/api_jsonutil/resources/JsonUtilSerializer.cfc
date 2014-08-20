<cfcomponent extends="taffy.core.baseSerializer">

	<cffunction
		name="getAsJson"
		output="false"
		taffy:mime="application/json"
		taffy:default="true">
			<cfreturn variables.jsonUtil.serialize(variables.data) />
	</cffunction>

	<cffunction name="setJSONUtil" output="false">
		<cfargument name="JSONUtil" required="true" />
		<cfset variables.jsonUtil = arguments.JSONUtil />
	</cffunction>

</cfcomponent>
