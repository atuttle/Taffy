<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{artistId}/art">

	<cffunction name="init" returntype="taffy.core.restapi">

		<!--- add some uri mappings that apply to this object --->
		<cfset addMap("/artist/{artistId}/art") />

		<cfreturn this />
	</cffunction>

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf(this) /><!--- return this to simulate a complex data type --->
	</cffunction>

</cfcomponent>