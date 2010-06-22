<cfcomponent extends="taffy.core.restapi" taffy_uri="/artfarts">

	<cffunction name="get" access="public" output="false">

<cfset var tmp = application.beanFactory.getBeanDefinitionList() />
<cfdump var="#tmp[1].getBeanClass()#"><cfabort>

		<cfreturn representationOf(this.configBean).withStatus(200) />
	</cffunction>

	<!--- this will be called by the bean factory's autowire functionality --->
	<cffunction name="setConfigBean" access="public" output="false" returnType="void">
		<cfargument name="configBean" type="any" required="true" hint="configBean object" />
		<cfset this.configBean = arguments.configBean />
	</cffunction>

</cfcomponent>