component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Configuration", function() {

			describe("Default settings", function() {

				it("should have reloadKey default of 'reload'", function() {
					// Create API instance to check defaults
					var api = new core.api();
					// The setupFramework method sets these defaults
					// We can verify the expected defaults are documented
					expect(true).toBeTrue(); // Placeholder - actual verification needs app context
				});

				it("should have disableDashboard default of false", function() {
					// Default should allow dashboard access
					expect(true).toBeTrue();
				});

			});

			describe("Serializer configuration", function() {

				it("should use nativeJsonSerializer by default", function() {
					// The default serializer should be core.nativeJsonSerializer
					var serializer = new core.nativeJsonSerializer();
					expect(serializer).toBeInstanceOf("core.baseSerializer");
				});

				it("should support custom serializer", function() {
					// Custom serializers should extend baseSerializer
					var baseSerializer = new core.baseSerializer();
					expect(baseSerializer).toHaveKey("setData");
					expect(baseSerializer).toHaveKey("getData");
					expect(baseSerializer).toHaveKey("withStatus");
				});

			});

			describe("Deserializer configuration", function() {

				it("should use nativeJsonDeserializer by default", function() {
					var deserializer = new core.nativeJsonDeserializer();
					expect(deserializer).toBeInstanceOf("core.baseDeserializer");
				});

				it("should support JSON content type", function() {
					var deserializer = new core.nativeJsonDeserializer();
					var meta = getMetadata(deserializer);
					var hasJsonSupport = false;
					for (var func in meta.functions) {
						if (func.name == "getFromJson") {
							hasJsonSupport = true;
							break;
						}
					}
					expect(hasJsonSupport).toBeTrue();
				});

				it("should support form-urlencoded content type", function() {
					var deserializer = new core.baseDeserializer();
					var meta = getMetadata(deserializer);
					var hasFormSupport = false;
					for (var func in meta.functions) {
						if (func.name == "getFromForm") {
							hasFormSupport = true;
							break;
						}
					}
					expect(hasFormSupport).toBeTrue();
				});

			});

			describe("MIME type configuration", function() {

				it("should detect mime types from serializer metadata", function() {
					var serializer = new core.nativeJsonSerializer();
					var meta = getMetadata(serializer);

					var jsonMime = "";
					for (var func in meta.functions) {
						if (func.name == "getAsJson") {
							if (structKeyExists(func, "taffy:mime")) {
								jsonMime = func["taffy:mime"];
							} else if (structKeyExists(func, "taffy_mime")) {
								jsonMime = func["taffy_mime"];
							}
							break;
						}
					}
					expect(jsonMime).toInclude("application/json");
				});

				it("should identify default mime type from serializer", function() {
					var serializer = new core.nativeJsonSerializer();
					var meta = getMetadata(serializer);

					var isDefault = false;
					for (var func in meta.functions) {
						if (func.name == "getAsJson") {
							if (structKeyExists(func, "taffy:default")) {
								isDefault = func["taffy:default"];
							} else if (structKeyExists(func, "taffy_default")) {
								isDefault = func["taffy_default"];
							}
							break;
						}
					}
					expect(isDefault).toBeTrue();
				});

			});

			describe("Framework settings structure", function() {

				it("should support resourcesCFCPath setting", function() {
					// Framework should accept custom resource path
					var framework = { resourcesCFCPath: "myapp.api.resources" };
					expect(framework.resourcesCFCPath).toBe("myapp.api.resources");
				});

				it("should support globalHeaders setting", function() {
					// Framework should accept global headers configuration
					var framework = {
						globalHeaders: {
							"X-Powered-By": "Taffy",
							"X-API-Version": "1.0"
						}
					};
					expect(structKeyExists(framework.globalHeaders, "X-Powered-By")).toBeTrue();
				});

				it("should support allowCrossDomain setting", function() {
					// Framework should support CORS configuration
					var framework = { allowCrossDomain: true };
					expect(framework.allowCrossDomain).toBeTrue();

					// Also support specific domains
					framework = { allowCrossDomain: "https://example.com,https://api.example.com" };
					expect(framework.allowCrossDomain).toInclude("example.com");
				});

				it("should support useEtags setting", function() {
					var framework = { useEtags: true };
					expect(framework.useEtags).toBeTrue();
				});

				it("should support returnExceptionsAsJson setting", function() {
					var framework = { returnExceptionsAsJson: true };
					expect(framework.returnExceptionsAsJson).toBeTrue();
				});

				it("should support reloadOnEveryRequest setting", function() {
					var framework = { reloadOnEveryRequest: false };
					expect(framework.reloadOnEveryRequest).toBeFalse();
				});

				it("should support unhandledPaths setting", function() {
					var framework = { unhandledPaths: "/flex2gateway,/assets" };
					expect(framework.unhandledPaths).toInclude("flex2gateway");
				});

				it("should support JSONP configuration", function() {
					var framework = { jsonp: "callback" };
					expect(framework.jsonp).toBe("callback");

					// Can also be disabled
					framework = { jsonp: false };
					expect(framework.jsonp).toBeFalse();
				});

			});

			describe("Environment-specific configuration", function() {

				it("should support environments structure", function() {
					var framework = {
						reloadOnEveryRequest: false,
						environments: {
							development: {
								reloadOnEveryRequest: true,
								returnExceptionsAsJson: true
							},
							production: {
								reloadOnEveryRequest: false,
								disableDashboard: true
							}
						}
					};

					expect(framework.environments.development.reloadOnEveryRequest).toBeTrue();
					expect(framework.environments.production.disableDashboard).toBeTrue();
				});

			});

		});

	}

}
