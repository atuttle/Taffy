<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{artistId}/art/{artId}">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="put" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

	<cffunction name="delete" access="public" output="false">
		<cfreturn representationOf({whatever=true}) /><!--- return this to simulate a complex data type --->
	</cffunction>

</cfcomponent>