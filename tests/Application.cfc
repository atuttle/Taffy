component {

	this.name = "TaffyTestHarness_" & hash(getCurrentTemplatePath());
	this.sessionManagement = false;

	// Set up mappings for tests
	variables.testsPath = getDirectoryFromPath(getCurrentTemplatePath());
	variables.rootPath = getDirectoryFromPath(variables.testsPath);

	this.mappings["/taffy"] = variables.rootPath;
	this.mappings["/testbox"] = variables.testsPath & "testbox";
	this.mappings["/tests"] = variables.testsPath;
	this.mappings["/resources"] = variables.testsPath & "resources";

	function onApplicationStart() {
		return true;
	}

	function onRequestStart(targetPath) {
		// Initialize minimal Taffy context for tests that need it
		if (!structKeyExists(application, "_taffy")) {
			application._taffy = {
				settings: {
					serializer: "taffy.core.nativeJsonSerializer",
					noDataSends204NoContent: false
				},
				factory: createObject("component", "taffy.core.factory").init(),
				compat: {
					queryToArray: "missing",
					queryToStruct: "missing"
				}
			};
		}
		return true;
	}

}
