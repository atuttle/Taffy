<cfcomponent extends="taffy.core.resource" taffy_uri="/artist/{artistId}/art">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

</cfcomponent>