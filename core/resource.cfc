<cfcomponent hint="base class for taffy REST components">

	<!--- helper functions --->
	<cffunction name="representationOf" access="private" output="false" hint="returns an object capable of serializing the data in a variety of formats">
		<cfargument name="data" required="true" hint="any simple or complex data that should be returned for the request" />
		<cfargument name="customRepresentationClass" type="string" required="false" default="" hint="pass in the dot.notation.cfc.path for your custom representation object" />

		<cfif arguments.customRepresentationClass eq "">
			<cfreturn getRepInstance(application._taffy.settings.defaultRepresentationClass).setData(arguments.data) />
		<cfelse>
			<cfreturn getRepInstance(arguments.customRepresentationClass).setData(arguments.data) />
		</cfif>

	</cffunction>

	<cffunction name="noData" access="private" output="false" hint="use this function to return only headers to the consumer, no data">
		<cfreturn createObject("component", application._taffy.settings.defaultRepresentationClass).noData() />
	</cffunction>

	<!---
		function that gets the representation class instance
		-- if the argument is a beanName, the bean is returned from the factory;
		-- otherwise it is assumed to be a cfc path and that cfc instance is returned
	--->
	<cffunction name="getRepInstance" access="private" output="false">
		<cfargument name="repClass" type="string" />
		<cfif application._taffy.factory.containsBean(arguments.repClass)>
			<cfreturn application._taffy.factory.getBean(arguments.repClass) />
		<cfelse>
			<cfreturn createObject("component", arguments.repClass) />
		</cfif>
	</cffunction>

</cfcomponent>