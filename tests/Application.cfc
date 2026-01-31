<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";
		this.dirPath = getDirectoryFromPath(getCurrentTemplatePath());
		this.mappings["/testbox"] = this.dirPath & "testbox/";
		this.mappings["/tests"] = this.dirPath;
		this.mappings["/taffy"] = this.dirPath & "../";

		variables.framework = {};
		variables.framework.disableDashboard = false;
		variables.framework.reloadKey = "reload";

		function getEnvironment(){
			return "test";
		}
	</cfscript>
</cfcomponent>
