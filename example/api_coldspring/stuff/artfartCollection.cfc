<cfcomponent extends="taffy.core.restapi" taffy_uri="/artfarts">

	<cffunction name="get" access="public" output="false">
<cfdump var="#this#"><cfabort>
		<cfset var q = "" />
		<cfquery name="q" datasource="cfartgallery" cachedwithin="#createTimeSpan(0,0,0,1)#">
			select * from artists
		</cfquery>
		<cfreturn representationOf(q).withStatus(200) />
	</cffunction>

	<!--- this should be called by the bean factory's autowire functionality --->
	<cffunction name="setConfigBean" access="public" output="false" returnType="void">
		<cfargument name="configBean" type="any" required="true" hint="configBean object" />
		<cfset this.configBean = arguments.configBean />
	</cffunction>

</cfcomponent>