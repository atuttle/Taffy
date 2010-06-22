<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{artistId}/art/{artId}">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<cffunction name="put" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

	<cffunction name="delete" access="public" output="false">
		<cfreturn representationOf({whatever=true}).withStatus(200) />
	</cffunction>

</cfcomponent>