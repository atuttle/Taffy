component extends="taffy.core.api" {

	this.name = "TaffyE2ETestAPI_" & hash(getCurrentTemplatePath());
	this.sessionManagement = false;

	variables.testApiPath = getDirectoryFromPath(getCurrentTemplatePath());
	variables.rootPath = getDirectoryFromPath(left(variables.testApiPath, len(variables.testApiPath) - 1));
	variables.rootPath = getDirectoryFromPath(left(variables.rootPath, len(variables.rootPath) - 1));

	this.mappings["/taffy"] = variables.rootPath;
	this.mappings["/resources"] = variables.testApiPath & "resources";

	variables.framework = {
		disableDashboard: true,
		disabledDashboardRedirect: "",
		returnExceptionsAsJson: true
	};

	function onApplicationStart() {
		return super.onApplicationStart();
	}

	function onRequestStart(targetPath) {
		return super.onRequestStart(targetPath);
	}

}
