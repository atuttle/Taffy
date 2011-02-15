<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/tunnel/{id}">
	
	<cffunction name="get">
		<cfargument name="id" />
		
		<cfset var echo = {} />
		<cfset echo.actualMethod = "get" />
		
		<cfreturn representationOf(echo).withStatus(200) />
	</cffunction>
	
	<cffunction name="put">
		<cfargument name="id" />
		
		<cfset var echo = {} />
		<cfset echo.actualMethod = "put" />
		
		<cfreturn representationOf(echo).withStatus(200) />
	</cffunction>
	
	<cffunction name="delete">
		<cfargument name="id" />
		
		<cfset var echo = {} />
		<cfset echo.actualMethod = "delete" />
		
		<cfreturn representationOf(echo).withStatus(200) />
	</cffunction>
</cfcomponent>