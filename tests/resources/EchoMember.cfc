<cfcomponent extends="taffy.core.resource" taffy:uri="/echo/{id}">

	<cfproperty name="customJsonRepresentation" default="initial" />

	<cffunction name="get">
		<cfargument name="id" />
		<cfset local.headers = {}/>
		<cfset local.headers['x-dude'] = "dude!" />
		<cfset local.res = {} />
		<cfset local.res.id = arguments.id />
		<cfif structKeyExists(arguments, "dataFromOTR")>
			<cfset local.res.dataFromOTR = arguments.dataFromOTR />
		</cfif>
		<cfreturn representationOf(local.res).withStatus(999).withHeaders(local.headers) />
	</cffunction>

	<cffunction name="put">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>

	<cffunction name="post">
		<cfargument name="id" />
		<cfreturn representationOf(arguments).withStatus(200) />
	</cffunction>

</cfcomponent>