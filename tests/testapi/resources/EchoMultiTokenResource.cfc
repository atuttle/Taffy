component extends="taffy.core.resource" taffy:uri="/echo/{parentId}/child/{childId}" output="false" {

	function get(required string parentId, required string childId) output="false" {
		return rep({ method: "GET", parentId: arguments.parentId, childId: arguments.childId });
	}

}
