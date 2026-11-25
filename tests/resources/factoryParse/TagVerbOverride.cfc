<cfcomponent extends="taffy.core.resource" taffy:uri="/factory-parse/custom">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({ method: "GET" }) />
	</cffunction>

	<cffunction name="updatePartial" access="public" output="false" taffy_verb="PATCH">
		<cfreturn representationOf({ method: "PATCH" }) />
	</cffunction>

	<cffunction access="public" output="false" taffy:verb="OPTIONS" name="handleOptions">
		<cfreturn representationOf({ method: "OPTIONS" }) />
	</cffunction>

</cfcomponent>
