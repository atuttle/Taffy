component extends="taffy.core.openapiProvider" output="false" {

	variables.instanceId = createUUID();

	public struct function getComponents() {
		return {
			"schemas": {
				"Echo": {
					"type": "object",
					"properties": {
						"id": { "type": "string" },
						"method": { "type": "string" }
					}
				}
			}
		};
	}

	public array function getGlobalParameters() {
		return [
			{
				"name": "X-Trace-Id",
				"in": "header",
				"required": false,
				"schema": { "type": "string" },
				"description": "Global trace header."
			}
		];
	}

	public array function getExcludeParameters() {
		return [ "internalContext" ];
	}

	public struct function afterGenerate(required struct spec) {
		if (!structKeyExists(application, "openApiProviderAfterGenerateCount")) {
			application.openApiProviderAfterGenerateCount = 0;
		}
		application.openApiProviderAfterGenerateCount = application.openApiProviderAfterGenerateCount + 1;

		arguments.spec["x-provider-afterGenerate"] = true;
		arguments.spec["x-provider-afterGenerate-count"] = application.openApiProviderAfterGenerateCount;
		arguments.spec["x-provider-instance-id"] = variables.instanceId;
		return arguments.spec;
	}

}
