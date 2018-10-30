<cfcomponent extends="taffy.core.resource" taffy:uri="/dateCalback" hint="Collection of dates">

	<cffunction name="formatDate" access="private" output="false" hint="Format dates in ISO 8601 format">
		<cfargument name="row" type="any" required="yes" />

		<cfif isDate(row.foo)>
			<cfset row.foo = dateFormat(row.foo,'yyyy-mm-dd')&'T'&timeFormat(row.foo, 'HH:mm:ss.lZ')>
		</cfif>

		<cfreturn row>
	</cffunction>

	<cffunction name="get" access="public" output="false" hint="Get some collection of dates">

		<cfset var qry = queryNew("id,foo", "integer,date") />
		<cfset var i = 0 />
		<cfloop from="1" to="15" index="i">
			<cfset tmp = queryAddRow(qry) />
			<cfset tmp = querySetCell(qry, "id", i) />
			<cfset tmp = querySetCell(qry, "foo", dateadd("s",RandRange(1, 5000),now())) />
		</cfloop>

		<cfreturn representationOf(queryToArray(qry,formatDate)).withStatus(200) />

	</cffunction>

</cfcomponent>
