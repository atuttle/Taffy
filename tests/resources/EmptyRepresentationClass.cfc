<cfcomponent extends="taffy.core.genericRepresentation">

	<cfset structDelete(this, "getAsJson")/>
	<cfset structDelete(variables, "getAsJson")/>

</cfcomponent>