<cfcomponent extends="taffy.core.resource">
	<cfif structKeyExists(request, "_testsRunning")>
		<cfthrow message="Fail">
	</cfif>	
</cfcomponent>