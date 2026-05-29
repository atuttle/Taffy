component extends="taffy.core.resource" taffy:uri="/echo/{id}" output="false" {

	function get(required string id, string internalContext = "") output="false" {
		return rep({ method: "GET", id: arguments.id });
	}

	public struct function getOpenAPIDocs() {
		return {
			"summary": "Fetch echo",
			"parameters": [
				{
					"name": "X-Trace-Id",
					"in": "header",
					"required": false,
					"schema": { "type": "string" },
					"description": "Endpoint trace header."
				}
			],
			"responses": {
				"200": {
					"description": "Echo response.",
					"content": {
						"application/json": {
							"schema": { "$ref": "##/components/schemas/Echo" }
						}
					}
				}
			}
		};
	}

	function put(required string id, string name = "", string internalContext = "") output="false" {
		return rep({ method: "PUT", id: arguments.id, name: arguments.name });
	}

	function delete(required string id) output="false" {
		return rep({ method: "DELETE", id: arguments.id })
			.withStatus(200)
			.withHeaders({ "X-Deleted-Id": arguments.id });
	}

}
