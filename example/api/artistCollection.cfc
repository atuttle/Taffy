<cfcomponent extends="taffy.core.restapi" taffy_uri="/artists">

	<cffunction name="init" returntype="taffy.core.restapi">

		<!--- add some uri mappings that apply to this object --->
		<cfset addMap("/artists") />

		<cfreturn this />
	</cffunction>

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