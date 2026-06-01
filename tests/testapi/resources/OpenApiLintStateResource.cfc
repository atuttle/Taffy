component extends="taffy.core.resource" taffy:uri="/openapi-lint-state" output="false" {

	function get() output="false" {
		return rep({
			brokenResourceInvoked = structKeyExists(application, "openApiBrokenResourceInvoked") ? application.openApiBrokenResourceInvoked : 0
		});
	}

}
