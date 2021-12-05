<cfcomponent extends="taffy.core.resource" taffy:uri="/uriWithForwardSlash{,},uriAliasWithoutFowardSlash">

	<cffunction name="get">
		<cfreturn noData() />
	</cffunction>

</cfcomponent>