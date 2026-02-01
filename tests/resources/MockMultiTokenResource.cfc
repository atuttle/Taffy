component extends="core.resource" taffy:uri="/users/{userId}/orders/{orderId}" {

	/**
	 * GET /users/{userId}/orders/{orderId} - Returns order for a user
	 */
	function get(required string userId, required string orderId) {
		return rep({
			userId: arguments.userId,
			orderId: arguments.orderId,
			method: "GET"
		});
	}

}
