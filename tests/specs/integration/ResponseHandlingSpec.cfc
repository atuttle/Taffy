component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Set up minimal application context
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

		describe("Response Handling", function() {

			describe("Status codes", function() {

				it("should default to 200 OK", function() {
					var resource = new tests.resources.MockSimpleResource();
					var result = resource.get();
					expect(result.getStatus()).toBe(200);
					expect(result.getStatusText()).toBe("OK");
				});

				it("should support 201 Created", function() {
					var resource = new tests.resources.MockSimpleResource();
					var result = resource.post(name = "Test");
					expect(result.getStatus()).toBe(201);
					expect(result.getStatusText()).toBe("Created");
				});

				it("should support 404 Not Found", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ error: "Resource not found" }).withStatus(404);
					expect(serializer.getStatus()).toBe(404);
					expect(serializer.getStatusText()).toBe("Not Found");
				});

				it("should support 400 Bad Request", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ error: "Invalid input" }).withStatus(400);
					expect(serializer.getStatus()).toBe(400);
					expect(serializer.getStatusText()).toBe("Bad Request");
				});

				it("should support 500 Internal Server Error", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ error: "Something went wrong" }).withStatus(500);
					expect(serializer.getStatus()).toBe(500);
					expect(serializer.getStatusText()).toBe("Internal Server Error");
				});

				it("should support custom status text", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.withStatus(299, "Custom Success");
					expect(serializer.getStatus()).toBe(299);
					expect(serializer.getStatusText()).toBe("Custom Success");
				});

			});

			describe("Response headers", function() {

				it("should set custom headers", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ id: 123 })
						.withHeaders({ "X-Request-Id": "abc123" });
					var headers = serializer.getHeaders();
					expect(headers["X-Request-Id"]).toBe("abc123");
				});

				it("should set Location header for created resources", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ id: 456 })
						.withStatus(201)
						.withHeaders({ "Location": "/items/456" });
					expect(serializer.getHeaders()["Location"]).toBe("/items/456");
				});

				it("should set multiple headers", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.withHeaders({
						"X-Rate-Limit": "100",
						"X-Rate-Remaining": "99",
						"X-Cache-Control": "no-cache"
					});
					var headers = serializer.getHeaders();
					expect(headers["X-Rate-Limit"]).toBe("100");
					expect(headers["X-Rate-Remaining"]).toBe("99");
					expect(headers["X-Cache-Control"]).toBe("no-cache");
				});

			});

			describe("JSON serialization", function() {

				it("should serialize response data as JSON", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ message: "Hello", count: 42 });
					var json = serializer.getAsJson();
					expect(isJSON(json)).toBeTrue();
					var parsed = deserializeJSON(json);
					expect(parsed.message).toBe("Hello");
					expect(parsed.count).toBe(42);
				});

				it("should serialize nested structures", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({
						user: {
							name: "John",
							email: "john@example.com"
						},
						permissions: ["read", "write"]
					});
					var json = serializer.getAsJson();
					var parsed = deserializeJSON(json);
					expect(parsed.user.name).toBe("John");
					expect(parsed.permissions).toBeArray();
				});

				it("should serialize array responses", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData([
						{ id: 1, name: "Item 1" },
						{ id: 2, name: "Item 2" }
					]);
					var json = serializer.getAsJson();
					var parsed = deserializeJSON(json);
					expect(parsed).toBeArray();
					expect(arrayLen(parsed)).toBe(2);
				});

				it("should handle boolean values correctly", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({
						active: true,
						deleted: false
					});
					var json = serializer.getAsJson();
					var parsed = deserializeJSON(json);
					expect(parsed.active).toBeTrue();
					expect(parsed.deleted).toBeFalse();
				});

			});

			describe("noData() and noContent()", function() {

				it("noData() should return empty response when setting is false", function() {
					application._taffy.settings.noDataSends204NoContent = false;
					var serializer = new taffy.core.nativeJsonSerializer();
					var result = serializer.noData();
					// Should still be 200 with empty data
					expect(result.getStatus()).toBe(200);
				});

				it("noData() should return 204 when setting is true", function() {
					application._taffy.settings.noDataSends204NoContent = true;
					var serializer = new taffy.core.nativeJsonSerializer();
					var result = serializer.noData();
					expect(result.getStatus()).toBe(204);
					// Reset setting
					application._taffy.settings.noDataSends204NoContent = false;
				});

				it("noContent() should return 204", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					var result = serializer.noContent();
					expect(result.getStatus()).toBe(204);
					expect(result.getStatusText()).toBe("No Content");
				});

				it("noContent() should set Content-Type to text/plain", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					var result = serializer.noContent();
					var headers = result.getHeaders();
					expect(headers["Content-Type"]).toBe("text/plain");
				});

			});

			describe("Response type detection", function() {

				it("should identify textual response type", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setData({ message: "test" });
					expect(serializer.getType()).toBe("textual");
				});

				it("should identify filename response type", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setFileName("/path/to/file.pdf");
					expect(serializer.getType()).toBe("filename");
				});

				it("should identify filedata response type", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setFileData(toBinary(toBase64("test data")));
					expect(serializer.getType()).toBe("filedata");
				});

				it("should identify imagedata response type", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setImageData(toBinary(toBase64("image data")));
					expect(serializer.getType()).toBe("imagedata");
				});

			});

			describe("File streaming responses", function() {

				it("should configure file download response", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setFileName("/path/to/report.pdf")
						.withMime("application/pdf");

					expect(serializer.getFileName()).toBe("/path/to/report.pdf");
					expect(serializer.getFileMime()).toBe("application/pdf");
					expect(serializer.getType()).toBe("filename");
				});

				it("should configure binary data response", function() {
					var binaryData = toBinary(toBase64("PDF content here"));
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setFileData(binaryData)
						.withMime("application/pdf");

					expect(serializer.getFileData()).toBe(binaryData);
					expect(serializer.getFileMime()).toBe("application/pdf");
				});

				it("should configure file delete after download", function() {
					var serializer = new taffy.core.nativeJsonSerializer();
					serializer.setFileName("/tmp/temp-report.pdf")
						.withMime("application/pdf")
						.andDelete(true);

					expect(serializer.getDeleteFile()).toBeTrue();
				});

			});

		});

	}

}
