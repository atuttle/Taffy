component extends="taffy.core.resource" taffy:uri="/openapi-broken" output="false" {

	function get() output="false" {
		if (!structKeyExists(application, "openApiBrokenResourceInvoked")) {
			application.openApiBrokenResourceInvoked = 0;
		}
		application.openApiBrokenResourceInvoked++;
		return rep({ method: "GET" });
	}

	public struct function getOpenAPIDocs() {
		return {
			"responses": {
				"200": {
					"description": "Broken ref fixture.",
					"content": {
						"application/json": {
							"schema": { "$ref": "##/components/schemas/DoesNotExist" }
						}
					}
				}
			}
		};
	}

}
