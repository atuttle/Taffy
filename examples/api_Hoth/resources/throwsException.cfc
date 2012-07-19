<cfcomponent extends="taffy.core.resource" taffy_uri="/foo">

	<cffunction name="get" access="public" output="false">
		<cfthrow message="this is the message" detail="this is the detail" />
	</cffunction>

</cfcomponent>