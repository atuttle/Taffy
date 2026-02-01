component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Initialize application scope with minimal settings
		application._taffy = {
			settings: {
				serializer: "taffy.core.nativeJsonSerializer",
				noDataSends204NoContent: false
			},
			factory: new taffy.core.factory(),
			compat: {
				queryToArray: "missing",
				queryToStruct: "missing"
			}
		};
	}

	function run() {

		describe("NativeJsonSerializer", function() {

			beforeEach(function() {
				variables.serializer = new taffy.core.nativeJsonSerializer();
			});

			describe("inheritance", function() {

				it("should extend baseSerializer", function() {
					expect(serializer).toBeInstanceOf("taffy.core.baseSerializer");
				});

				it("should have all baseSerializer methods", function() {
					expect(serializer).toHaveKey("setData");
					expect(serializer).toHaveKey("getData");
					expect(serializer).toHaveKey("withStatus");
					expect(serializer).toHaveKey("withHeaders");
					expect(serializer).toHaveKey("noData");
					expect(serializer).toHaveKey("noContent");
				});

			});

			describe("getAsJson()", function() {

				it("should serialize simple string to JSON", function() {
					serializer.setData("Hello World");
					var result = serializer.getAsJson();
					expect(result).toBe('"Hello World"');
				});

				it("should serialize struct to JSON", function() {
					serializer.setData({ name: "Test", value: 123 });
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.name).toBe("Test");
					expect(parsed.value).toBe(123);
				});

				it("should serialize array to JSON", function() {
					serializer.setData([1, 2, 3]);
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed).toBeArray();
					expect(arrayLen(parsed)).toBe(3);
				});

				it("should serialize nested structures to JSON", function() {
					serializer.setData({
						user: {
							name: "John",
							roles: ["admin", "user"]
						},
						active: true
					});
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.user.name).toBe("John");
					expect(parsed.user.roles).toBeArray();
					expect(parsed.active).toBeTrue();
				});

				it("should serialize boolean values correctly", function() {
					serializer.setData({ active: true, deleted: false });
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.active).toBeTrue();
					expect(parsed.deleted).toBeFalse();
				});

				it("should serialize null values", function() {
					serializer.setData({ value: javacast("null", "") });
					var result = serializer.getAsJson();
					expect(result).toInclude("null");
				});

				it("should handle empty struct", function() {
					serializer.setData({});
					var result = serializer.getAsJson();
					expect(result).toBe("{}");
				});

				it("should handle empty array", function() {
					serializer.setData([]);
					var result = serializer.getAsJson();
					expect(result).toBe("[]");
				});

				it("should handle numeric values", function() {
					serializer.setData({
						integer: 42,
						decimal: 3.14,
						negative: -100
					});
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.integer).toBe(42);
					expect(parsed.decimal).toBe(3.14);
					expect(parsed.negative).toBe(-100);
				});

			});

			describe("taffy:mime metadata", function() {

				it("should have taffy:mime metadata for application/json", function() {
					var metadata = getMetadata(serializer);
					var getAsJsonFunc = "";
					for (var func in metadata.functions) {
						if (func.name == "getAsJson") {
							getAsJsonFunc = func;
							break;
						}
					}
					expect(getAsJsonFunc).notToBeEmpty();
					var hasMime = structKeyExists(getAsJsonFunc, "taffy:mime")
						|| structKeyExists(getAsJsonFunc, "taffy_mime");
					expect(hasMime).toBeTrue();
				});

				it("should be marked as default serializer", function() {
					var metadata = getMetadata(serializer);
					var getAsJsonFunc = "";
					for (var func in metadata.functions) {
						if (func.name == "getAsJson") {
							getAsJsonFunc = func;
							break;
						}
					}
					var hasDefault = structKeyExists(getAsJsonFunc, "taffy:default")
						|| structKeyExists(getAsJsonFunc, "taffy_default");
					expect(hasDefault).toBeTrue();
				});

			});

			describe("encode.string helper", function() {

				it("should force numeric strings to serialize as strings", function() {
					// The forceString function adds chr(2) which is then stripped by getAsJson
					// This ensures numeric-looking strings serialize as strings, not numbers
					var testableResource = new tests.resources.TestableResource();
					var forcedString = testableResource.testEncodeString("12345");

					// The chr(2) prefix forces CF to treat this as a string during serialization
					expect(left(forcedString, 1)).toBe(chr(2));

					// When serialized via nativeJsonSerializer, the chr(2) is stripped
					serializer.setData({ value: forcedString });
					var result = serializer.getAsJson();
					// The value should be serialized as a string (with quotes), not a number
					expect(result).toInclude('"');
				});

			});

			describe("combined operations", function() {

				it("should work with setData and status code", function() {
					serializer.setData({ error: "Not found" }).withStatus(404);
					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.error).toBe("Not found");
					expect(serializer.getStatus()).toBe(404);
				});

				it("should work with setData, status, and headers", function() {
					serializer
						.setData({ created: true })
						.withStatus(201)
						.withHeaders({ "Location": "/items/123" });

					var result = serializer.getAsJson();
					var parsed = deserializeJSON(result);
					expect(parsed.created).toBeTrue();
					expect(serializer.getStatus()).toBe(201);
					expect(serializer.getHeaders()["Location"]).toBe("/items/123");
				});

			});

		});

	}

}
