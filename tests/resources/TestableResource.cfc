component extends="taffy.core.resource" {

	/**
	 * Expose encode.string for testing
	 */
	function testEncodeString(required string data) {
		return variables.encode.string(arguments.data);
	}

	/**
	 * Expose qToArray for testing
	 */
	function testQToArray(required query q, any cb) {
		if (structKeyExists(arguments, "cb")) {
			return qToArray(arguments.q, arguments.cb);
		}
		return qToArray(arguments.q);
	}

	/**
	 * Expose qToStruct for testing
	 */
	function testQToStruct(required query q, any cb) {
		if (structKeyExists(arguments, "cb")) {
			return qToStruct(arguments.q, arguments.cb);
		}
		return qToStruct(arguments.q);
	}

}
