<cfcomponent extends="taffy.core.resource" taffy_uri="/factory-parse/artists">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf({ ok: true, method: "GET" }).withStatus(200) />
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfreturn representationOf({ ok: true, method: "POST" }).withStatus(201) />
	</cffunction>

</cfcomponent>
