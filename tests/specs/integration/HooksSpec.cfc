component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Hooks", function() {

			describe("onTaffyRequest hook", function() {

				it("should be defined in api.cfc", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("onTaffyRequest");
				});

				it("should accept required parameters", function() {
					var api = new taffy.core.api();
					var meta = getMetadata(api);
					var hookFunc = "";
					for (var func in meta.functions) {
						if (func.name == "onTaffyRequest") {
							hookFunc = func;
							break;
						}
					}
					expect(hookFunc).notToBeEmpty();
					expect(hookFunc.parameters).toBeArray();

					// Should have all expected parameters
					var paramNames = [];
					for (var param in hookFunc.parameters) {
						arrayAppend(paramNames, param.name);
					}
					expect(arrayFindNoCase(paramNames, "verb")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "cfc")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "requestArguments")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "mimeExt")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "headers")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "methodMetadata")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "matchedURI")).toBeGT(0);
				});

				it("should return true by default", function() {
					var api = new taffy.core.api();
					var result = api.onTaffyRequest(
						verb = "GET",
						cfc = "testResource",
						requestArguments = {},
						mimeExt = "json",
						headers = {},
						methodMetadata = {},
						matchedURI = "/test"
					);
					expect(result).toBeTrue();
				});

			});

			describe("onTaffyRequestEnd hook", function() {

				it("should be defined in api.cfc", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("onTaffyRequestEnd");
				});

				it("should accept required parameters", function() {
					var api = new taffy.core.api();
					var meta = getMetadata(api);
					var hookFunc = "";
					for (var func in meta.functions) {
						if (func.name == "onTaffyRequestEnd") {
							hookFunc = func;
							break;
						}
					}
					expect(hookFunc).notToBeEmpty();

					var paramNames = [];
					for (var param in hookFunc.parameters) {
						arrayAppend(paramNames, param.name);
					}

					// Should include response-related parameters
					expect(arrayFindNoCase(paramNames, "parsedResponse")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "originalResponse")).toBeGT(0);
					expect(arrayFindNoCase(paramNames, "statusCode")).toBeGT(0);
				});

				it("should return true by default", function() {
					var api = new taffy.core.api();
					var result = api.onTaffyRequestEnd(
						verb = "GET",
						cfc = "testResource",
						requestArguments = {},
						mimeExt = "json",
						headers = {},
						methodMetadata = {},
						matchedURI = "/test",
						parsedResponse = '{"test":true}',
						originalResponse = { test: true },
						statusCode = 200
					);
					expect(result).toBeTrue();
				});

			});

			describe("Caching hooks", function() {

				it("should have validCacheExists hook", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("validCacheExists");
				});

				it("validCacheExists should return false by default", function() {
					var api = new taffy.core.api();
					var result = api.validCacheExists(cacheKey = "test-key");
					expect(result).toBeFalse();
				});

				it("should have setCachedResponse hook", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("setCachedResponse");
				});

				it("should have getCachedResponse hook", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("getCachedResponse");
				});

				it("should have getCacheKey hook", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("getCacheKey");
				});

				it("getCacheKey should generate key from request params", function() {
					var api = new taffy.core.api();
					var requestArgs = { id: 123 };
					var result = api.getCacheKey(
						cfc = "testResource",
						requestArguments = requestArgs,
						matchedURI = "/items/{id}"
					);
					expect(result).toInclude("/items/{id}");
				});

			});

			describe("getEnvironment hook", function() {

				it("should be defined in api.cfc", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("getEnvironment");
				});

				it("should return empty string by default", function() {
					var api = new taffy.core.api();
					var result = api.getEnvironment();
					expect(result).toBe("");
				});

			});

			describe("Hook extensibility", function() {

				it("should allow overriding onTaffyRequest in subclass", function() {
					// Any class extending taffy.core.api can override hooks
					var api = new taffy.core.api();
					// The base api has the hook that can be overridden
					expect(api).toHaveKey("onTaffyRequest");
					// Verify it's a function that can be overridden
					expect(isCustomFunction(api.onTaffyRequest)).toBeTrue();
				});

			});

			describe("Basic auth helper", function() {

				it("should have getBasicAuthCredentials method", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("getBasicAuthCredentials");
				});

				it("getBasicAuthCredentials should return struct with username and password", function() {
					var api = new taffy.core.api();
					var result = api.getBasicAuthCredentials();
					expect(result).toBeStruct();
					expect(result).toHaveKey("username");
					expect(result).toHaveKey("password");
				});

				it("should return empty credentials when no auth header", function() {
					var api = new taffy.core.api();
					var result = api.getBasicAuthCredentials();
					expect(result.username).toBe("");
					expect(result.password).toBe("");
				});

			});

			describe("Helper methods", function() {

				it("should have getHostname helper", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("getHostname");
					var hostname = api.getHostname();
					expect(len(hostname)).toBeGT(0);
				});

				it("should have addHeaders helper", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("addHeaders");
				});

				it("should have rep helper for responses", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("rep");
				});

				it("should have representationOf helper", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("representationOf");
				});

				it("should have noData helper", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("noData");
				});

				it("should have noContent helper", function() {
					var api = new taffy.core.api();
					expect(api).toHaveKey("noContent");
				});

			});

		});

	}

}
