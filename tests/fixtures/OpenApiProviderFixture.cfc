component extends="taffy.core.openapiProvider" output="false" {

	public struct function getComponents() {
		return {
			"schemas": {
				"Fixture": { "type": "object" }
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

	public struct function getResponseDefaults(required array mediaTypes) {
		return {
			"default": {
				"description": "Fixture default response."
			}
		};
	}

	public struct function afterGenerate(required struct spec) {
		arguments.spec["x-fixture-afterGenerate"] = true;
		return arguments.spec;
	}

}
