<!---
	Core component class for backwards compatible HTTP status header handling for ColdFusion 2025+
	where the statustext attribute has been deprecated.
	
	This CFC provides the structured, testable implementation with dependency injection support.
	For a simple global function interface, see cfHeaderHelper.cfm which wraps this component.
--->
<cfcomponent hint="Utility component for backwards compatible cfheader handling">

	<!--- Cache the CF version check since it won't change during execution --->
	<cfset variables.isCF2025OrLater = "" />
	<cfset variables.serverInfo = "" />

	<!--- Constructor to inject server information --->
	<cffunction name="init" access="public" output="false" returntype="any" hint="Constructor with optional server info injection">
		<cfargument name="serverInfo" type="struct" required="false" default="#structNew()#" hint="Server info for testing/injection" />
		
		<cfscript>
			if (structIsEmpty(arguments.serverInfo)) {
				// Only reference server scope if no injection provided
				variables.serverInfo = server;
			} else {
				variables.serverInfo = arguments.serverInfo;
			}
		</cfscript>
		
		<cfreturn this />
	</cffunction>

	<cffunction name="setStatusHeader" access="public" output="false" returntype="void" hint="Sets HTTP status header with backwards compatibility for CF 2025">
		<cfargument name="statusCode" type="numeric" required="true" hint="HTTP status code to set" />
		<cfargument name="statusText" type="string" required="false" default="" hint="HTTP status text (optional for CF 2025+)" />
		
		<cfscript>
			if (isColdFusion2025OrLater()) {
				cfheader(statuscode=arguments.statusCode);
			} else {
				if (len(arguments.statusText)) {
					cfheader(statuscode=arguments.statusCode, statustext=arguments.statusText);
				} else {
					cfheader(statuscode=arguments.statusCode);
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="isColdFusion2025OrLater" access="public" output="false" returntype="boolean" hint="Detects if running ColdFusion 2025 or later">
		<cfscript>
			// Cache the result since CF version won't change during execution
			if (variables.isCF2025OrLater == "") {
				var cfVersion = 0;
				if (structKeyExists(variables.serverInfo, "coldfusion") && 
					structKeyExists(variables.serverInfo.coldfusion, "productname") &&
					variables.serverInfo.coldfusion.productname contains "ColdFusion") {
					// Extract the first number from the productversion string, regardless of format
					var versionMatch = reMatch("\d+", variables.serverInfo.coldfusion.productversion);
					if (arrayLen(versionMatch) > 0) {
						cfVersion = val(versionMatch[1]);
					} else {
						cfVersion = 0;
					}
				}
				variables.isCF2025OrLater = (cfVersion >= 2025);
			}
			return variables.isCF2025OrLater;
		</cfscript>
	</cffunction>

</cfcomponent>