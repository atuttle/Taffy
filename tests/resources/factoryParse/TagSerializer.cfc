<cfcomponent extends="taffy.core.baseSerializer">

	<cffunction name="getAsJSON" taffy:mime="application/json" taffy:default="true" output="false">
		<cfreturn serializeJSON(variables.data) />
	</cffunction>

</cfcomponent>
