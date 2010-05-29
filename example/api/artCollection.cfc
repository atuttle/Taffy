<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{artistId}/art">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

</cfcomponent>