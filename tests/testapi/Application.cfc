component extends="taffy.core.api" {

	this.name = "TaffyE2ETestAPI_" & hash(getCurrentTemplatePath());
	this.sessionManagement = false;

	variables.framework = {
		reloadOnEveryRequest: true,
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
