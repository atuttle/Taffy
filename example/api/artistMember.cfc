<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{id}">

	<cffunction name="init" returntype="taffy.core.restapi">

		<!--- add some uri mappings that apply to this object --->
		<cfset addMap("/artist/{id}") />

		<cfreturn this />
	</cffunction>

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="put" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="delete" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

</cfcomponent>