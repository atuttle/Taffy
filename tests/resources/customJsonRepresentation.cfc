<cfcomponent extends="taffy.core.nativeJsonRepresentation">
	
	<cffunction name="getAsJSON" output="false"
		taffy_mime="text/json"
		taffy_default="true"
		hint="serializes data as JSON">
	
		<cfreturn super.getAsJson() />
	</cffunction>

	<cffunction name="getAsXML" output="false" taffy:mime="text/xml">
		<cfreturn "FAIL FAIL FAIL" />
	</cffunction>

</cfcomponent>