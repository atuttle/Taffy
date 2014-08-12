<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = "rate_limiting_example";

		function onApplicationStart(){
			application.accessLog = queryNew('apiKey,accessTime','varchar,time');
			application.accessLimit = 100; //requests
			application.accessPeriod = 60; //seconds

			return super.onApplicationStart();
		}

		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){
			var usage = 0;

			//require some api key
			if (!structKeyExists(requestArguments, "apiKey")){
				return noData().withStatus(401, "API Key Required");
			}

			//check usage
			usage = getAccessRate(requestArguments.apiKey);
			if (usage lte application.accessLimit){
				logAccess(requestArguments.apiKey);
				return true;
			}else{
				return noData().withStatus(420, "Enhance your calm");
			}

			return true;
		}
	</cfscript>

	<cffunction name="getAccessRate" access="private" output="false">
		<cfargument name="apiKey" required="true" />
		<cfset var local = structNew() />
		<!--- now get matches for the current api key --->
		<cfquery name="local.accessLookup" dbtype="query">
			select accessTime
			from application.accessLog
			where apiKey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.apiKey#" />
			and accessTime > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateAdd("s",(-1 * application.accessPeriod),now())#" />
		</cfquery>
		<!--- if access log is getting long, do some cleanup --->
		<cfif local.accessLookup.recordCount gt application.accessLimit>
			<cfset pruneAccessLog() />
		</cfif>
		<cfreturn local.accessLookup.recordCount />
	</cffunction>

	<cffunction name="logAccess" access="private" output="true">
		<cfargument name="apiKey" required="true" type="string" />
		<cfset var qLog = '' />
		<cflock timeout="10" type="readonly" name="logging">
			<cfset queryAddRow(application.accessLog)/>
			<cfset querySetCell(application.accessLog, "accessTime", now()) />
			<cfset querySetCell(application.accessLog, "apiKey", arguments.apiKey) />
		</cflock>
	</cffunction>

	<cffunction name="pruneAccessLog" access="private" output="false">
		<cflock timeout="10" type="readonly" name="logging">
			<cfquery name="application.accessLog" dbtype="query">
				delete
				from application.accessLog
				where accessTime < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateAdd("s",(-1 * application.accessPeriod),now())#" />
			</cfquery>
		</cflock>
	</cffunction>

</cfcomponent>
