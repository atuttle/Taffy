component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Initialize application scope with minimal settings required by resource.cfc
		application._taffy = {
			settings: {
				serializer: "core.nativeJsonSerializer",
				noDataSends204NoContent: false
			},
			factory: new core.factory(),
			compat: {
				queryToArray: "missing",
				queryToStruct: "missing"
			}
		};
		// Create a mock API instance for testing URI methods
		variables.api = new core.api();
	}

	function run() {

		describe("URI Matching", function() {

			describe("convertURItoRegex()", function() {

				it("should convert simple static URI to regex", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/users");
					expect(result).toBeStruct();
					expect(result).toHaveKey("uriRegex");
					expect(result).toHaveKey("tokens");
					expect(result.tokens).toBeArray();
					expect(arrayLen(result.tokens)).toBe(0);
				});

				it("should extract single token from URI", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{id}");
					expect(arrayLen(result.tokens)).toBe(1);
					expect(result.tokens[1]).toBe("id");
				});

				it("should extract multiple tokens from URI", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{userId}/orders/{orderId}");
					expect(arrayLen(result.tokens)).toBe(2);
					expect(result.tokens[1]).toBe("userId");
					expect(result.tokens[2]).toBe("orderId");
				});

				it("should handle mixed static and token segments", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/api/v1/users/{id}/profile");
					expect(arrayLen(result.tokens)).toBe(1);
					expect(result.tokens[1]).toBe("id");
				});

				it("should generate regex that matches expected URIs", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/items/{id}");
					var regex = result.uriRegex;

					// Should match /items/123
					expect(reFindNoCase(regex, "/items/123")).toBeGT(0);
					// Should match /items/abc
					expect(reFindNoCase(regex, "/items/abc")).toBeGT(0);
					// Should match with format extension
					expect(reFindNoCase(regex, "/items/123.json")).toBeGT(0);
				});

				it("should support custom regex patterns in tokens", function() {
					// Taffy supports {tokenName:regex} syntax
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{id:[0-9]+}");
					expect(result.tokens[1]).toBe("id");
					// The regex should only match numeric IDs
					var regex = result.uriRegex;
					expect(reFindNoCase(regex, "/users/123")).toBeGT(0);
				});

			});

			describe("URI regex matching", function() {

				it("should match exact static path", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/simple");
					expect(reFindNoCase(result.uriRegex, "/simple")).toBeGT(0);
				});

				it("should match path with trailing slash", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/simple");
					expect(reFindNoCase(result.uriRegex, "/simple/")).toBeGT(0);
				});

				it("should match path with format extension", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/items/{id}");
					expect(reFindNoCase(result.uriRegex, "/items/123.json")).toBeGT(0);
					expect(reFindNoCase(result.uriRegex, "/items/abc.xml")).toBeGT(0);
				});

				it("should not match unrelated paths", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{id}");
					expect(reFindNoCase(result.uriRegex, "/items/123")).toBe(0);
				});

				it("should handle deeply nested URIs", function() {
					var result = makePublic(api, "convertURItoRegex").convertURItoRegex("/api/v1/users/{userId}/orders/{orderId}/items/{itemId}");
					expect(arrayLen(result.tokens)).toBe(3);
					expect(reFindNoCase(result.uriRegex, "/api/v1/users/1/orders/2/items/3")).toBeGT(0);
				});

			});

			describe("Token value extraction", function() {

				it("should extract token values from matched URI", function() {
					var uriConfig = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{id}");
					var matchResult = reFindNoSuck(uriConfig.uriRegex, "/users/123");
					expect(matchResult).toBeArray();
					expect(arrayLen(matchResult)).toBeGTE(1);
					expect(matchResult[1]).toBe("123");
				});

				it("should extract multiple token values", function() {
					var uriConfig = makePublic(api, "convertURItoRegex").convertURItoRegex("/users/{userId}/orders/{orderId}");
					var matchResult = reFindNoSuck(uriConfig.uriRegex, "/users/42/orders/99");
					expect(arrayLen(matchResult)).toBeGTE(2);
					expect(matchResult[1]).toBe("42");
					expect(matchResult[2]).toBe("99");
				});

			});

			describe("sortURIMatchOrder()", function() {

				it("should sort URIs for proper matching order", function() {
					var endpoints = {
						"^/users/([^\/]+)": { srcUri: "/users/{id}" },
						"^/users": { srcUri: "/users" },
						"^/users/([^\/]+)/profile": { srcUri: "/users/{id}/profile" }
					};
					var result = makePublic(api, "sortURIMatchOrder").sortURIMatchOrder(endpoints);
					expect(result).toBeArray();
					// More specific patterns should be sorted appropriately
					expect(arrayLen(result)).toBe(3);
				});

			});

		});

	}

	/**
	 * Reimplementation of reFindNoSuck for testing
	 */
	private function reFindNoSuck(required string pattern, required string data, numeric startPos = 1) {
		var local = {};
		local.awesome = [];
		local.sucky = reFindNoCase(arguments.pattern, arguments.data, arguments.startPos, true);
		if (!isArray(local.sucky.len) || arrayLen(local.sucky.len) == 0) {
			return [];
		}
		for (local.i = 1; local.i <= arrayLen(local.sucky.len); local.i++) {
			if (local.sucky.len[local.i] > 0 && local.sucky.pos[local.i] > 0) {
				local.matchBody = mid(arguments.data, local.sucky.pos[local.i], local.sucky.len[local.i]);
				if (local.matchBody != arguments.data) {
					arrayAppend(local.awesome, local.matchBody);
				}
			}
		}
		return local.awesome;
	}

}
