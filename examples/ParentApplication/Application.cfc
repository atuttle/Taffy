<cfcomponent output="false">

	<cfscript>
		this.name = "taffy_ParentAppExample";
		this.applicationTimeout = createTimeSpan(0,2,0,0);
		this.sessionManagement = false;
		this.setClientCookies = true;
		this.scriptProtect = false;
	</cfscript>

	<cffunction name="onApplicationStart" returnType="boolean" output="false">

		<cfset application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory") />
		<cfset application.beanFactory.loadBeans('/taffy/examples/ParentApplication/config/coldspring.xml') />

		<cfparam name="application.init" default="#structNew()#" />
		<cfset application.init.app = true />

		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true" />

		<cfif not structKeyExists(application, "init") or not structKeyExists(application.init, "app")>
			<cfset onApplicationStart() />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>