component extends="taffy.core.resource" taffy:uri="/echo" output="false" {

	function get() output="false" {
		return rep({ method: "GET", message: "echo" });
	}

	function post(string name = "" taffy_minlength="1" taffy_maxlength="255", string value = "" taffy_maxlength="500") output="false" {
		return rep({ method: "POST", name: arguments.name, value: arguments.value })
			.withStatus(201);
	}

}
