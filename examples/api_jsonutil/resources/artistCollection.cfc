<cfcomponent extends="taffy.core.resource" taffy_uri="/artists">

	<cffunction name="get" access="public" output="false">
		<cfset var q = "" />
		<cfset var headers = structNew() />
		<cfquery name="q" datasource="cfartgallery" cachedwithin="#createTimeSpan(0,0,0,1)#">
			select * from artists
		</cfquery>
		<cfset headers["x-powered-by"] = "Taffy 1.1" />
		<cfreturn representationOf(q).withStatus(200).withHeaders(headers) />
	</cffunction>

	<cffunction name="post" access="public" output="false">
		<cfargument name="firstname" type="string" required="false" default="" />
		<cfargument name="lastname" type="string" required="false" default="" />
		<cfargument name="address" type="string" required="false" default="" />
		<cfargument name="city" type="string" required="false" default="" />
		<cfargument name="state" type="string" required="false" default="" />
		<cfargument name="postalcode" type="string" required="false" default="" />
		<cfargument name="email" type="string" required="false" default="" />
		<cfargument name="phone" type="string" required="false" default="" />
		<cfargument name="fax" type="string" required="false" default="" />
		<cfargument name="thepassword" type="string" required="false" default="" />
		<cfset var q = "" />
		<cfquery name="q" datasource="cfartgallery">
			insert into artists (firstname,lastname,address,city,state,postalcode,email,phone,fax,thepassword)
			values (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.firstname#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.lastname#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.address#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.city#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.postalcode#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.phone#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.fax#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thepassword#" />
			)
		</cfquery>
		<cfquery name="q" datasource="cfartgallery">
			select * from artists
			where
				firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.firstname#" />
				and lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.lastname#" />
				and address = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.address#" />
				and city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.city#" />
				and state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state#" />
				and postalcode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.postalcode#" />
				and email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />
				and phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.phone#" />
				and fax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.fax#" />
				and thepassword = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thepassword#" />
		</cfquery>
		<cfreturn representationOf(q).withStatus(200) />
	</cffunction>

	<!---
		The DELETE and PUT verbs are not implemented, so those actions are not permitted.
	 --->

</cfcomponent>