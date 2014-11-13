<cfcomponent extends="taffy.core.resource" taffy:uri="/artist/{id}" hint="some hint about this resource">

	<cffunction name="get" access="public" output="false">
		<cfargument name="id" type="numeric" required="true" />
		<cfset var q = ""/>
		<cfset var col = "" />
		<cfset var rtn = StructNew() />
		<cfquery name="q" datasource="cfartgallery">
			select * from artists where artistId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" />
		</cfquery>
		<cfif q.recordCount gt 0>
			<cfloop list="#q.ColumnList#" index="col">
				<cfset rtn[col] = q[col][1] />
			</cfloop>
			<cfreturn representationOf(rtn).withStatus(200) />
		<cfelse>
			<cfreturn noData().withStatus(404) />
		</cfif>
	</cffunction>

	<cffunction name="put" access="public" output="false">
		<cfargument name="id" type="numeric" required="true" />
		<cfargument name="firstname" type="string" required="false" default="" />
		<cfargument name="lastname" type="string" required="false" default="" />
		<cfargument name="address" type="string" required="false" default="" hint="some hint about this parameter" />
		<cfargument name="city" type="string" required="false" default="" />
		<cfargument name="state" type="string" required="false" default="" />
		<cfargument name="postalcode" type="string" required="false" default="" />
		<cfargument name="email" type="string" required="false" default="" />
		<cfargument name="phone" type="string" required="false" default="" />
		<cfargument name="fax" type="string" required="false" default="" />
		<cfargument name="thepassword" type="string" required="false" default="" />
		<cfset var q = "" />
		<cfquery name="q" datasource="cfartgallery">
			update artists
			set artistid=artistid
				<cfif len(arguments.firstname)>
					,firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.firstname#" />
				</cfif>
				<cfif len(arguments.lastname)>
					,lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.lastname#" />
				</cfif>
				<cfif len(arguments.address)>
					,address = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.address#" />
				</cfif>
				<cfif len(arguments.city)>
					,city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.city#" />
				</cfif>
				<cfif len(arguments.state)>
					,state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state#" />
				</cfif>
				<cfif len(arguments.postalcode)>
					,postalcode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.postalcode#" />
				</cfif>
				<cfif len(arguments.email)>
					,email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />
				</cfif>
				<cfif len(arguments.phone)>
					,phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.phone#" />
				</cfif>
				<cfif len(arguments.fax)>
					,fax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.fax#" />
				</cfif>
				<cfif len(arguments.thepassword)>
					,thepassword = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thepassword#" />
				</cfif>
				where artistid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#" />
		</cfquery>
		<cfreturn noData().withStatus(200) />
	</cffunction>

	<cffunction name="delete" access="public" output="false">
		<cfargument name="id" type="numeric" required="true" />
		<cfset var q = "" />
		<cfquery name="q" datasource="cfartgallery">
			delete from artists where artistid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#" />
		</cfquery>
		<cfreturn noData().withStatus(200) />
	</cffunction>

	<cffunction name="someInternalMethod" hint="you should not see this documentation...">
	</cffunction>

</cfcomponent>
