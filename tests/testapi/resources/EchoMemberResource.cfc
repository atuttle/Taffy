component extends="taffy.core.resource" taffy:uri="/echo/{id}" output="false" {

	function get(required string id) output="false" {
		return rep({ method: "GET", id: arguments.id });
	}

	function put(required string id, string name = "") output="false" {
		return rep({ method: "PUT", id: arguments.id, name: arguments.name });
	}

	function delete(required string id) output="false" {
		return rep({ method: "DELETE", id: arguments.id })
			.withStatus(200)
			.withHeaders({ "X-Deleted-Id": arguments.id });
	}

}
