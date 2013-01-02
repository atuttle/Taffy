<cfcomponent extends="taffy.core.resource" taffy:uri="/foo">
	
	<cffunction name="get">
		<cfreturn representationOf("hi").withStatus(200) />
	</cffunction>

</cfcomponent>