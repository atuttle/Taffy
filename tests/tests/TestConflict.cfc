<cfcomponent extends="base">

	<cffunction name="setup">
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />
		<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm?#application._taffy.settings.reloadkey#=#application._taffy.settings.reloadPassword#" />
	</cffunction>

	<cfscript>
		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			makePublic(variables.taffy, "getBeanFactory");
			variables.factory = variables.taffy.getBeanFactory();
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesConflict'), 'taffy.tests.resourcesConflict', expandPath('/taffy/tests/resourcesConflict'), true, variables.taffy);

		}

		function conflicting_URIs_get_skipped() {
			assertTrue(checkIfOneSkippedRessourceContainsExpectedException("errorCode", "taffy.resources.DuplicateUriPattern"), "Conflicting URIs not showing in errors");
		}
	</cfscript>


</cfcomponent>
