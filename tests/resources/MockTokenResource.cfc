component extends="taffy.core.resource" taffy:uri="/items/{id}" {

	/**
	 * GET /items/{id} - Returns an item by ID
	 */
	function get(required string id) {
		return rep({ id: arguments.id, name: "Item #arguments.id#", method: "GET" });
	}

	/**
	 * PUT /items/{id} - Updates an item
	 */
	function put(required string id, string name = "") {
		return rep({ id: arguments.id, name: arguments.name, updated: true, method: "PUT" });
	}

	/**
	 * DELETE /items/{id} - Deletes an item
	 */
	function delete(required string id) {
		return rep({ id: arguments.id, deleted: true, method: "DELETE" });
	}

}
