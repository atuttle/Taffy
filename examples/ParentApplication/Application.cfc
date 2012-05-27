<cfcomponent output="false">

	<cfscript>
		this.name = "taffy_ParentAppExample";//same name as parent folder application.cfc
		this.applicationTimeout = createTimeSpan(0,2,0,0);
		this.sessionManagement = false;
		this.setClientCookies = false;
		this.scriptProtect = false;
	</cfscript>

	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfinclude template="mixin/appInit.cfm" />
		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true" />

		<cfif structKeyExists(url, "reinit")>
			<cfset onApplicationStart() />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>