component extends="testbox.system.BaseSpec" {

	function run() {

		describe("NativeJsonDeserializer", function() {

			beforeEach(function() {
				variables.deserializer = new taffy.core.nativeJsonDeserializer();
			});

			describe("inheritance", function() {

				it("should extend baseDeserializer", function() {
					expect(deserializer).toBeInstanceOf("taffy.core.baseDeserializer");
				});

				it("should have getFromForm from parent", function() {
					expect(deserializer).toHaveKey("getFromForm");
				});

			});

			describe("getFromJson()", function() {

				it("should parse simple JSON object", function() {
					var body = '{"name":"John","age":30}';
					var result = deserializer.getFromJson(body);
					expect(result.name).toBe("John");
					expect(result.age).toBe(30);
				});

				it("should parse nested JSON objects", function() {
					var body = '{"user":{"name":"John","email":"john@example.com"},"active":true}';
					var result = deserializer.getFromJson(body);
					expect(result.user.name).toBe("John");
					expect(result.user.email).toBe("john@example.com");
					expect(result.active).toBeTrue();
				});

				it("should parse JSON with arrays", function() {
					var body = '{"items":[1,2,3],"tags":["a","b","c"]}';
					var result = deserializer.getFromJson(body);
					expect(result.items).toBeArray();
					expect(arrayLen(result.items)).toBe(3);
					expect(result.tags[1]).toBe("a");
				});

				it("should handle boolean values", function() {
					var body = '{"active":true,"deleted":false}';
					var result = deserializer.getFromJson(body);
					expect(result.active).toBeTrue();
					expect(result.deleted).toBeFalse();
				});

				it("should handle null values", function() {
					var body = '{"value":null,"other":"test"}';
					var result = deserializer.getFromJson(body);
					// Note: In Lucee, null values may not preserve the key in the struct
					// We verify the deserializer doesn't throw an error and returns a struct
					expect(result).toBeStruct();
					expect(result.other).toBe("test");
				});

				it("should handle numeric values", function() {
					var body = '{"integer":42,"decimal":3.14,"negative":-100}';
					var result = deserializer.getFromJson(body);
					expect(result.integer).toBe(42);
					expect(result.decimal).toBe(3.14);
					expect(result.negative).toBe(-100);
				});

				it("should handle empty object", function() {
					var body = '{}';
					var result = deserializer.getFromJson(body);
					expect(result).toBeStruct();
					expect(structIsEmpty(result)).toBeTrue();
				});

				it("should wrap non-struct JSON in _body key", function() {
					// When JSON is an array at root level, wrap it
					var body = '[1,2,3]';
					var result = deserializer.getFromJson(body);
					expect(structKeyExists(result, "_body")).toBeTrue();
					expect(result._body).toBeArray();
				});

				it("should wrap primitive JSON values in _body key", function() {
					var body = '"just a string"';
					var result = deserializer.getFromJson(body);
					expect(structKeyExists(result, "_body")).toBeTrue();
					expect(result._body).toBe("just a string");
				});

				it("should handle complex nested structures", function() {
					var body = '{
						"users": [
							{"id": 1, "name": "John", "roles": ["admin", "user"]},
							{"id": 2, "name": "Jane", "roles": ["user"]}
						],
						"metadata": {
							"total": 2,
							"page": 1
						}
					}';
					var result = deserializer.getFromJson(body);
					expect(result.users).toBeArray();
					expect(arrayLen(result.users)).toBe(2);
					expect(result.users[1].roles).toBeArray();
					expect(result.metadata.total).toBe(2);
				});

				it("should handle unicode characters", function() {
					var body = '{"message":"Hello \u4e16\u754c"}';
					var result = deserializer.getFromJson(body);
					expect(structKeyExists(result, "message")).toBeTrue();
				});

			});

			describe("taffy:mime metadata", function() {

				it("should have taffy:mime for application/json", function() {
					var metadata = getMetadata(deserializer);
					var func = "";
					for (var f in metadata.functions) {
						if (f.name == "getFromJson") {
							func = f;
							break;
						}
					}
					expect(func).notToBeEmpty();
					var hasMime = structKeyExists(func, "taffy:mime")
						|| structKeyExists(func, "taffy_mime");
					expect(hasMime).toBeTrue();

					// Check the actual mime types
					var mimeValue = structKeyExists(func, "taffy:mime")
						? func["taffy:mime"]
						: func["taffy_mime"];
					expect(mimeValue).toInclude("application/json");
				});

			});

		});

	}

}
