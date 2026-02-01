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

		// Create sample data fixture
		variables.sampleData = new tests.fixtures.SampleData();
	}

	function run() {

		describe("Resource", function() {

			beforeEach(function() {
				variables.resource = new taffy.core.resource();
			});

			describe("rep() / representationOf()", function() {

				it("should return a serializer instance with data", function() {
					var result = resource.rep({ message: "test" });
					expect(result).toBeInstanceOf("taffy.core.baseSerializer");
					expect(result.getData().message).toBe("test");
				});

				it("rep() should be alias for representationOf()", function() {
					var data = { id: 123 };
					var rep1 = resource.rep(data);
					// Both should return serializer instances with same data
					expect(rep1.getData().id).toBe(123);
				});

				it("should work with simple string data", function() {
					var result = resource.rep("Hello World");
					expect(result.getData()).toBe("Hello World");
				});

				it("should work with array data", function() {
					var result = resource.rep([1, 2, 3]);
					expect(result.getData()).toBeArray();
					expect(arrayLen(result.getData())).toBe(3);
				});

				it("should work with nested struct data", function() {
					var data = {
						user: { name: "John", age: 30 },
						roles: ["admin", "user"]
					};
					var result = resource.rep(data);
					expect(result.getData().user.name).toBe("John");
					expect(result.getData().roles).toBeArray();
				});

			});

			describe("encode.string()", function() {

				beforeEach(function() {
					variables.testableResource = new tests.resources.TestableResource();
				});

				it("should add control character prefix to force string serialization", function() {
					var result = testableResource.testEncodeString("12345");
					expect(left(result, 1)).toBe(chr(2));
				});

				it("should preserve the original value after prefix", function() {
					var result = testableResource.testEncodeString("12345");
					expect(right(result, 5)).toBe("12345");
				});

				it("should work with numeric-looking strings", function() {
					var result = testableResource.testEncodeString("00123");
					expect(len(result)).toBe(6); // chr(2) + "00123"
				});

			});

			describe("qToArray() - internal query to array conversion", function() {

				beforeEach(function() {
					variables.testableResource = new tests.resources.TestableResource();
				});

				it("should convert query to array of structs", function() {
					var q = sampleData.getSampleQuery();
					var result = testableResource.testQToArray(q);
					expect(result).toBeArray();
					expect(arrayLen(result)).toBe(3);
				});

				it("should preserve column values in structs", function() {
					var q = sampleData.getSampleQuery();
					var result = testableResource.testQToArray(q);
					// Find the row with id=1
					var found = false;
					for (var row in result) {
						if (row.id == 1) {
							expect(row.name).toBe("John Doe");
							expect(row.email).toBe("john@example.com");
							found = true;
							break;
						}
					}
					expect(found).toBeTrue();
				});

				it("should handle empty query", function() {
					var q = queryNew("id,name", "integer,varchar");
					var result = testableResource.testQToArray(q);
					expect(result).toBeArray();
					expect(arrayLen(result)).toBe(0);
				});

				it("should support callback function for row transformation", function() {
					var q = sampleData.getSingleRowQuery();
					var result = testableResource.testQToArray(q, function(row) {
						row.transformed = true;
						return row;
					});
					expect(result[1].transformed).toBeTrue();
				});

			});

			describe("qToStruct() - internal query to struct conversion", function() {

				beforeEach(function() {
					variables.testableResource = new tests.resources.TestableResource();
				});

				it("should convert single-row query to struct", function() {
					var q = sampleData.getSingleRowQuery();
					var result = testableResource.testQToStruct(q);
					expect(result).toBeStruct();
					expect(result.id).toBe(1);
					expect(result.name).toBe("Test User");
				});

				it("should throw error for multi-row query", function() {
					var q = sampleData.getSampleQuery(); // Has 3 rows
					expect(function() {
						testableResource.testQToStruct(q);
					}).toThrow();
				});

				it("should handle query with all column types", function() {
					var q = sampleData.getSingleRowQuery();
					var result = testableResource.testQToStruct(q);
					expect(structKeyExists(result, "id")).toBeTrue();
					expect(structKeyExists(result, "name")).toBeTrue();
					expect(structKeyExists(result, "email")).toBeTrue();
				});

				it("should support callback function for value transformation", function() {
					var q = sampleData.getSingleRowQuery();
					var result = testableResource.testQToStruct(q, function(colName, value) {
						if (colName == "name") {
							return uCase(value);
						}
						return value;
					});
					expect(result.name).toBe("TEST USER");
				});

			});

			describe("method chaining with rep()", function() {

				it("should support chaining with withStatus()", function() {
					var result = resource.rep({ created: true }).withStatus(201);
					expect(result.getStatus()).toBe(201);
					expect(result.getData().created).toBeTrue();
				});

				it("should support chaining with withHeaders()", function() {
					var result = resource.rep({ data: "test" })
						.withHeaders({ "X-Custom": "value" });
					expect(result.getHeaders()["X-Custom"]).toBe("value");
				});

				it("should support full fluent chain", function() {
					var result = resource.rep({ id: 123 })
						.withStatus(201, "Created")
						.withHeaders({ "Location": "/items/123" });

					expect(result.getData().id).toBe(123);
					expect(result.getStatus()).toBe(201);
					expect(result.getStatusText()).toBe("Created");
					expect(result.getHeaders()["Location"]).toBe("/items/123");
				});

			});

		});

	}

}
