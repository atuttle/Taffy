component output="false" {

	public struct function getComponents() {
		return {};
	}

	public array function getGlobalParameters() {
		return [];
	}

	public array function getExcludeParameters() {
		return [];
	}

	public struct function getResponseDefaults(required array mediaTypes) {
		var content = {};
		for (var i = 1; i <= arrayLen(arguments.mediaTypes); i++) {
			content[arguments.mediaTypes[i]] = { "schema": {} };
		}

		var undocumented = { "description": "Response not documented." };
		if (arrayLen(arguments.mediaTypes)) {
			undocumented["content"] = content;
		}

		return { "default": undocumented };
	}

	public struct function schemaRef(required string name) {
		return { "$ref": "##/components/schemas/" & arguments.name };
	}

	public struct function jsonContent(required struct schema) {
		return {
			"application/json": {
				"schema": arguments.schema
			}
		};
	}

	public struct function jsonResponses(required string statusCode, required string description, required struct schema) {
		var responses = {};
		responses[arguments.statusCode] = {
			"description": arguments.description,
			"content": jsonContent(arguments.schema)
		};
		return responses;
	}

	public struct function jsonRequestBody(required struct schema, boolean isRequired = false) {
		return {
			"required": arguments.isRequired,
			"content": jsonContent(arguments.schema)
		};
	}

	public struct function afterGenerate(required struct spec) {
		return arguments.spec;
	}

}
