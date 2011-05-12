<cfcomponent extends="taffy.core.resource" taffy:uri="/artist/{artistId}/art" hint="Collection of art data">

	<cfset variables.dummyData = StructNew() />
	<cfset variables.dummyData.whatever = true />

	<cffunction name="get" access="public" output="false" hint="Get some collection of art data">
		<cfargument name="artistId" type="numeric" required="false" default="-1" hint="If included, filters the results to match the requested id. -1 (default) includes all." />
		<cfreturn representationOf(variables.dummyData).withStatus(200) />
	</cffunction>

	<cffunction name="post" access="public" output="false" hint="Insert a new art record">
		<cfreturn representationOf(variables.dummyData).withStatus(200) />
	</cffunction>

</cfcomponent>