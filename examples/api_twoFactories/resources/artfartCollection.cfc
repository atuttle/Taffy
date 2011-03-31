<cfcomponent extends="taffy.core.resource" taffy_uri="/artfarts">

	<cffunction name="get" access="public" output="false">
		<cfreturn representationOf(variables.fakeData.getData()).withStatus(200) />
	</cffunction>

	<!--- this will be called by the bean factory's autowire functionality --->
	<cffunction name="setFakeData" access="public" output="false" returnType="void">
		<cfargument name="fakeDataObj" type="any" required="true" hint="Shared FakeData object" />
		<cfset variables.fakeData = arguments.fakeDataObj />
	</cffunction>

</cfcomponent>