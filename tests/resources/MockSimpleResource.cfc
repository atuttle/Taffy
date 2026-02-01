component extends="taffy.core.resource" taffy:uri="/simple" {

	/**
	 * GET /simple - Returns a simple response
	 */
	function get() {
		return rep({ message: "Hello from simple resource", method: "GET" });
	}

	/**
	 * POST /simple - Creates something
	 */
	function post(string name = "") {
		return rep({ message: "Created", name: arguments.name, method: "POST" })
			.withStatus(201, "Created");
	}

}
