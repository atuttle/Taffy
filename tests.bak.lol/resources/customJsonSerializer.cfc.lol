<cfcomponent extends="taffy.core.nativeJsonSerializer">

	<cfproperty name="dependency1" />

	<cffunction name="getAsJSON" output="false"
		taffy_mime="text/json"
		taffy_default="true"
		hint="serializes data as JSON">

		<cfreturn super.getAsJson() />
	</cffunction>

	<cffunction name="getAsXML" output="false" taffy:mime="text/xml">
		<cfreturn "FAIL FAIL FAIL" />
	</cffunction>

	<cffunction name="setDependency2">
		<cfargument name="dependency2" />
		<cfset this.dependency2 = arguments.dependency2 />
	</cffunction>

</cfcomponent>
