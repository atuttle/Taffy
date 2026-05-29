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

	public struct function afterGenerate(required struct spec) {
		return arguments.spec;
	}

}
