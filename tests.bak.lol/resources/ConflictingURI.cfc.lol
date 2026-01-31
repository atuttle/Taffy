<cfcomponent extends="taffy.core.resource" taffy:uri="/conflict/{URI}, /conflict/{URI}" hint="I have multiple uris">

	<cffunction name="get">
		<cfargument name="uri" type="string" default="0" />
		<cfset local.res = {} />
		<cfset local.res.uri = arguments.uri />

		<cfreturn representationOf(local.res) />
	</cffunction>

</cfcomponent>
