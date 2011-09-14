<cfcomponent extends="taffy.core.nativeJsonRepresentation">
	<cffunction name="getAsJSON" output="false"
		taffy_mime="text/json"
		taffy_default="true"
		hint="serializes data as JSON">
	
		<cfreturn super.getAsJson() />
	</cffunction>
</cfcomponent>