<cfcomponent extends="taffy.core.resource" taffy:uri="/throwException">

	<cffunction name="get">
		<cfthrow message="this is the exception message." detail="this is the exception detail." />
	</cffunction>

</cfcomponent>