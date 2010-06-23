<cfcomponent output="false">

	<cffunction name="getData" output="false" access="public">
		<cfset var qry = queryNew("id,foo", "integer,varchar") />
		<cfset var i = 0 />
		<cfloop from="1" to="15" index="i">
			<cfset tmp = queryAddRow(qry) />
			<cfset tmp = querySetCell(qry, "id", i) />
			<cfset tmp = querySetCell(qry, "foo", toBase64(hash("bar" & i), "utf-8")) />
		</cfloop>
		<cfreturn qry />
	</cffunction>

</cfcomponent>
