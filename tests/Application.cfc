component {

	this.name = "TaffyTestHarness_" & hash(getCurrentTemplatePath());
	this.sessionManagement = false;

	// Set up mappings for tests
	variables.testsPath = getDirectoryFromPath(getCurrentTemplatePath());
	// Strip trailing slash before calling getDirectoryFromPath to reliably get parent dir across engines
	variables.rootPath = getDirectoryFromPath(left(variables.testsPath, len(variables.testsPath) - 1));

	this.mappings["/taffy"] = variables.rootPath;
	this.mappings["/testbox"] = variables.testsPath & "testbox";
	this.mappings["/tests"] = variables.testsPath;
	this.mappings["/resources"] = variables.testsPath & "resources";

	// Also set component paths for Lucee 6 compatibility
	this.componentPaths = [
		{
			"physical": variables.rootPath,
			"archive": "",
			"primary": "physical",
			"inspectTemplate": "always"
		}
	];

	function onApplicationStart() {
		// Initialize minimal Taffy context for tests that need it
		application._taffy = {
			settings: {
				serializer: "core.nativeJsonSerializer",
				noDataSends204NoContent: false
			},
			factory: new core.factory(),
			compat: {
				queryToArray: "missing",
				queryToStruct: "missing"
			}
		};
		return true;
	}

	function onRequestStart(targetPath) {
		return true;
	}

}
