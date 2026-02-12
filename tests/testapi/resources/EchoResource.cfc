component extends="taffy.core.resource" taffy:uri="/echo" output="false" {

	function get() output="false" {
		return rep({ method: "GET", message: "echo" });
	}

	function post(string name = "", string value = "") output="false" {
		return rep({ method: "POST", name: arguments.name, value: arguments.value })
			.withStatus(201);
	}

}
