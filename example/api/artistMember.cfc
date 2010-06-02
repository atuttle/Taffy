<cfcomponent extends="taffy.core.restapi" taffy_uri="/artist/{id}">

	<cffunction name="get" access="public" output="false">
		<cfargument name="id" type="numeric" required="true" />
		<cfset var q = ""/>
		<cfquery name="q" datasource="cfartgallery">
			select * from artists where artistId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" />
		</cfquery>
		<cfreturn representationOf(q).withStatus(200) />
	</cffunction>

	<cffunction name="put" access="public" output="false">
		<cfreturn representationOf({}).withStatus(200) />
	</cffunction>

	<cffunction name="delete" access="public" output="false">
		<cfreturn representationOf({}).withStatus(200) />
	</cffunction>

</cfcomponent>