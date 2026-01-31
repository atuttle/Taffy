<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/towel">
	
	<cffunction name="get">
		<cfreturn representationOf("don't panic!").withStatus(200) />
	</cffunction>

</cfcomponent>
