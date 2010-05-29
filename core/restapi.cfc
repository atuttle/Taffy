<cfcomponent hint="base class for taffy REST components">

	<cfparam name="variables.maps" default="#arrayNew(1)#" />

	<!--- helper functions --->
	<cffunction name="addMap" access="public" output="false" returnType="void">
		<cfargument name="map" type="string" required="true" default="" hint="example: /user/{id}" />
		<cfset arrayAppend(variables.maps, arguments.map) />
	</cffunction>

	<cffunction name="getMaps">
		<cfreturn variables.maps />
	</cffunction>

	<cffunction name="representationOf" output="false" hint="returns an object capable of serializing the data in a variety of formats">
		<cfargument name="data" required="true" hint="any simple or complex data that should be returned for the request" />
		<cfargument name="customRepresentationClass" type="string" required="false" default="" hint="pass in the dot.notation.cfc.path for your custom representation object" />

		<cfif arguments.customRepresentationClass eq "">
			<cfreturn createObject("component", "taffy.core.genericRepresentation").setData(arguments.data) />
		<cfelse>
			<cfreturn createObject("component", arguments.customRepresentationClass).setData(arguments.data) />
		</cfif>

	</cffunction>

</cfcomponent>