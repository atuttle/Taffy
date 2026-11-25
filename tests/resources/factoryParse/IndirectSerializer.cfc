component extends="tests.resources.factoryParse.LocalSerializerBase" {

	function getAsJson() taffy:mime="application/json;text/json" taffy:default="true" {
		return serializeJSON(variables.data);
	}

}
