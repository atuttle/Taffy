<cfcomponent extends="taffy.core.resource" taffy_uri="/customers" hint="Collection of customers">

	<cffunction name="get">
		<cfset var qry = queryNew("id,foo,bar,DATETIMEcreATed,name", "integer,string,string,datetime,string") />
		<cfset var i = 0 />
		<cfloop from="1" to="5" index="i">
			<cfset queryAddRow(qry) />
			<cfset querySetCell(qry, "id", i) />
			<cfset querySetCell(qry, "foo", "foo") />
			<cfset querySetCell(qry, "bar", "bar") />
			<cfset querySetCell(qry, "DATETIMEcreATed", now()) />
			<cfset querySetCell(qry, "name", "Test Testerson") />
		</cfloop>

		<cfreturn rep(queryToArrayOf( qry, types.Customer )) />

	</cffunction>

</cfcomponent>
