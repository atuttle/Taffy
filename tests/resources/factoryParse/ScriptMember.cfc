component extends="taffy.core.resource" taffy:uri="/factory-parse/artist/{id}" {

	function get(required string id) {
		return rep({ id: arguments.id, method: "GET" });
	}

	function put(required string id) {
		return rep({ id: arguments.id, method: "PUT" });
	}

	function delete(required string id) {
		return noData().withStatus(204);
	}

}
