<cfcomponent extends="taffy.core.resource" taffy:uri="/date" hint="Collection of dates">

	<cffunction name="get" access="public" output="false" hint="Get some collection of dates">

		<cfset var qry = queryNew("id,foo", "integer,date") />
		<cfset var i = 0 />
		<cfloop from="1" to="15" index="i">
			<cfset tmp = queryAddRow(qry) />
			<cfset tmp = querySetCell(qry, "id", i) />
			<cfset tmp = querySetCell(qry, "foo", dateadd("s",RandRange(1, 5000),now())) />
		</cfloop>

		<cfreturn representationOf(queryToArray(qry)).withStatus(200) />

	</cffunction>

</cfcomponent>