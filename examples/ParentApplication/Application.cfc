<cfcomponent output="false">

	<cfscript>
		this.name = "taffy_ParentAppExample";//same name as parent folder application.cfc
		this.applicationTimeout = createTimeSpan(0,2,0,0);
		this.sessionManagement = false;
		this.setClientCookies = false;
		this.scriptProtect = false;
	</cfscript>

	<cffunction name="onApplicationStart" returnType="boolean" output="false">

		<cfset application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory") />
		<cfset application.beanFactory.loadBeans('/taffy/examples/ParentApplication/config/coldspring.xml') />

		<cfparam name="application.parentInit" default="true" />

		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true" />

		<!--- if the PARENT application has not been initialized, or if user is requesting reinit... --->
		<cfif
			not structKeyExists(application, "parentInit")
			or structKeyExists(url, "reinit")>
				<cfset onApplicationStart() />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>