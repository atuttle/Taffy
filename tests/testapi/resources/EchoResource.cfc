component extends="taffy.core.resource" taffy:uri="/echo" {

	function get() {
		return rep({ method: "GET", message: "echo" });
	}

	function post(string name = "", string value = "") {
		return rep({ method: "POST", name: arguments.name, value: arguments.value })
			.withStatus(201);
	}

}
