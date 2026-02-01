component extends="taffy.core.resource" taffy:uri="/custom" {

	/**
	 * Standard GET method
	 */
	function get() {
		return rep({ message: "Standard GET", method: "GET" });
	}

	/**
	 * Custom PATCH method using taffy_verb metadata
	 */
	function updatePartial() taffy_verb="PATCH" {
		return rep({ message: "Custom PATCH handler", method: "PATCH" });
	}

	/**
	 * Custom OPTIONS method using taffy_verb metadata (underscore style)
	 */
	function handleOptions() taffy_verb="OPTIONS" {
		return rep({ message: "Custom OPTIONS handler", method: "OPTIONS" });
	}

}
