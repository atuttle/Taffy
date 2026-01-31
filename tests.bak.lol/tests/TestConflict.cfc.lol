<cfcomponent extends="base">

	<cffunction name="setup">
		<cfset reloadFramework()>
	</cffunction>

	<cfscript>
		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			makePublic(variables.taffy, "getBeanFactory");
			variables.factory = variables.taffy.getBeanFactory();
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesConflict'), 'taffy.tests.resourcesConflict', expandPath('/taffy/tests/resourcesConflict'), true, variables.taffy);

		}

		function test_conflicting_URIs_get_skipped() {
			assertTrue(checkIfOneSkippedRessourceContainsExpectedException("errorCode", "taffy.resources.DuplicateUriPattern"), "Conflicting URIs not showing in errors");
		}
	</cfscript>


</cfcomponent>
