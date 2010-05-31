<cfcomponent extends="taffy.core.restapi" taffy_uri="/artists">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<!---
		The DELETE and PUT verbs are not implemented, so those actions are not permitted.
	 --->

</cfcomponent>