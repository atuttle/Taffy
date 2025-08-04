<!---
	Global utility function wrapper for backwards compatible cfheader handling.
	
	This provides a simple function interface that wraps the cfHeaderUtils.cfc component.
	The CFC is cached in application scope for performance. This helper allows code to call
	setTaffyStatusHeader() directly without managing component instances.
--->

<cffunction name="setTaffyStatusHeader" output="false" returntype="void" hint="Sets HTTP status header with backwards compatibility for CF 2025">
	<cfargument name="statusCode" type="numeric" required="true" hint="HTTP status code to set" />
	<cfargument name="statusText" type="string" required="false" default="" hint="HTTP status text (optional for CF 2025+)" />
	
	<cfscript>
		// Ensure thread-safe initialization using an exclusive application-scoped lock
		if (!structKeyExists(application, "_taffyHeaderUtils")) {
			lock name="taffyHeaderUtilsInit" scope="application" type="exclusive" timeout="5" {
				// Double-check inside the lock to prevent race conditions
				if (!structKeyExists(application, "_taffyHeaderUtils")) {
					application._taffyHeaderUtils = createObject("component", "taffy.core.cfHeaderUtils").init();
				}
			}
		}
		
		application._taffyHeaderUtils.setStatusHeader(arguments.statusCode, arguments.statusText);
	</cfscript>
</cffunction>