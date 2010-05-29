<cfcomponent extends="taffy.core.restapi" taffy_uri="/artists">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<!---
		The DELETE and PUT verbs are not implemented, so those actions are not permitted.
	 --->

</cfcomponent>