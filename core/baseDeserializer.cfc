<cfcomponent output="false" hint="a helper class to decode input data">

	<!--- the most basic of input handlers, available in all APIs --->
	<cffunction name="getFromForm" output="false" taffy:mime="application/x-www-form-urlencoded" hint="get data from form post">
		<cfargument name="body" hint="the textual request body" />
		<cfset var response = {} />
		<cfset var pairs = listToArray(arguments.body, "&") />
		<cfset var pair = "" />
		<cfset var kv = [] />
		<cfset var ix = 0 />
		<cfset var k = "" />
		<cfset var v = "" />

		<cfif not find('=', arguments.body)>
			<cfset throwError(400, "You've indicated that you're sending form-encoded data but it doesn't appear to be valid. Aborting request.") />
		</cfif>

		<cfloop from="1" to="#arrayLen(pairs)#" index="ix">
			<cfset pair = pairs[ix] />
			<cfset kv = listToArray(pair, "=", true) />
			<cfset k = kv[1] />
			<cfset v = urlDecode( kv[2] ) />
			<cfif structKeyExists( response, k )>
				<cfset response[k] = listAppend(response[k], v)>
			<cfelse>
				<cfset response[k] = v>
			</cfif>
		</cfloop>

		<cfreturn response />
	</cffunction>

	<!--- ============================ --->
	<!--- Helpers                      --->
	<!--- ============================ --->

	<cffunction name="throwError" access="private" output="false" returntype="void">
		<cfargument name="statusCode" type="numeric" default="500" />
		<cfargument name="msg" type="string" required="true" hint="message to return to api consumer" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfcontent reset="true" />
		<cfset addHeaders(arguments.headers) />
		<cfheader statuscode="#arguments.statusCode#" statustext="#arguments.msg#" />
		<cfabort />
	</cffunction>

	<cffunction name="addHeaders" access="private" output="false" returntype="void">
		<cfargument name="headers" type="struct" required="true" />
		<cfset var h = '' />
		<cfif !structIsEmpty(arguments.headers)>
			<cfloop list="#structKeyList(arguments.headers)#" index="h">
				<cfheader name="#h#" value="#arguments.headers[h]#" />
			</cfloop>
		</cfif>
	</cffunction>

</cfcomponent>
