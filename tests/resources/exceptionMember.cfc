<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/throwException">

	<cffunction name="get">
		<cfthrow message="this is the exception message." detail="this is the exception detail." />
	</cffunction>

</cfcomponent>