component extends="taffy.core.resource" taffy:uri="/echo/{parentId}/child/{childId}" {

	function get(required string parentId, required string childId) {
		return rep({ method: "GET", parentId: arguments.parentId, childId: arguments.childId });
	}

}
