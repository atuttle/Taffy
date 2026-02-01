component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Initialize application scope with minimal settings for noData() to work
		application._taffy = {
			settings: {
				noDataSends204NoContent: false
			}
		};
	}

	function run() {

		describe("BaseSerializer", function() {

			beforeEach(function() {
				variables.serializer = new core.baseSerializer();
			});

			describe("setData() and getData()", function() {

				it("should store and retrieve simple string data", function() {
					var data = "Hello World";
					serializer.setData(data);
					expect(serializer.getData()).toBe(data);
				});

				it("should store and retrieve struct data", function() {
					var data = { name: "Test", value: 123 };
					serializer.setData(data);
					var result = serializer.getData();
					expect(result.name).toBe("Test");
					expect(result.value).toBe(123);
				});

				it("should store and retrieve array data", function() {
					var data = [1, 2, 3, 4, 5];
					serializer.setData(data);
					expect(serializer.getData()).toBeArray();
					expect(arrayLen(serializer.getData())).toBe(5);
				});

				it("should return this for method chaining", function() {
					var result = serializer.setData("test");
					expect(result).toBeInstanceOf("core.baseSerializer");
				});

				it("should set type to textual (1) when setting data", function() {
					serializer.setData("test");
					expect(serializer.getType()).toBe("textual");
				});

			});

			describe("withStatus()", function() {

				it("should set status code with default text", function() {
					serializer.withStatus(200);
					expect(serializer.getStatus()).toBe(200);
					expect(serializer.getStatusText()).toBe("OK");
				});

				it("should set status code 201 with Created text", function() {
					serializer.withStatus(201);
					expect(serializer.getStatus()).toBe(201);
					expect(serializer.getStatusText()).toBe("Created");
				});

				it("should set status code 404 with Not Found text", function() {
					serializer.withStatus(404);
					expect(serializer.getStatus()).toBe(404);
					expect(serializer.getStatusText()).toBe("Not Found");
				});

				it("should set status code 500 with Internal Server Error text", function() {
					serializer.withStatus(500);
					expect(serializer.getStatus()).toBe(500);
					expect(serializer.getStatusText()).toBe("Internal Server Error");
				});

				it("should allow custom status text", function() {
					serializer.withStatus(418, "I'm a teapot - Custom");
					expect(serializer.getStatus()).toBe(418);
					expect(serializer.getStatusText()).toBe("I'm a teapot - Custom");
				});

				it("should use lookup table for known status codes", function() {
					serializer.withStatus(418);
					expect(serializer.getStatusText()).toBe("I'm a teapot");
				});

				it("should return this for method chaining", function() {
					var result = serializer.withStatus(200);
					expect(result).toBeInstanceOf("core.baseSerializer");
				});

				it("should handle all 2xx status codes", function() {
					serializer.withStatus(204);
					expect(serializer.getStatusText()).toBe("No Content");

					serializer.withStatus(206);
					expect(serializer.getStatusText()).toBe("Partial Content");
				});

				it("should handle 3xx redirect status codes", function() {
					serializer.withStatus(301);
					expect(serializer.getStatusText()).toBe("Moved Permanently");

					serializer.withStatus(302);
					expect(serializer.getStatusText()).toBe("Found");

					serializer.withStatus(304);
					expect(serializer.getStatusText()).toBe("Not Modified");
				});

				it("should handle 4xx client error status codes", function() {
					serializer.withStatus(400);
					expect(serializer.getStatusText()).toBe("Bad Request");

					serializer.withStatus(401);
					expect(serializer.getStatusText()).toBe("Unauthorized");

					serializer.withStatus(403);
					expect(serializer.getStatusText()).toBe("Forbidden");

					serializer.withStatus(405);
					expect(serializer.getStatusText()).toBe("Method Not Allowed");

					serializer.withStatus(422);
					expect(serializer.getStatusText()).toBe("Unprocessable Entity");

					serializer.withStatus(429);
					expect(serializer.getStatusText()).toBe("Too Many Requests");
				});

				it("should handle 5xx server error status codes", function() {
					serializer.withStatus(501);
					expect(serializer.getStatusText()).toBe("Not Implemented");

					serializer.withStatus(502);
					expect(serializer.getStatusText()).toBe("Bad Gateway");

					serializer.withStatus(503);
					expect(serializer.getStatusText()).toBe("Service Unavailable");

					serializer.withStatus(504);
					expect(serializer.getStatusText()).toBe("Gateway Timeout");
				});

			});

			describe("withHeaders()", function() {

				it("should set custom headers", function() {
					var headers = { "X-Custom-Header": "value1", "X-Another": "value2" };
					serializer.withHeaders(headers);
					var result = serializer.getHeaders();
					expect(result["X-Custom-Header"]).toBe("value1");
					expect(result["X-Another"]).toBe("value2");
				});

				it("should return this for method chaining", function() {
					var result = serializer.withHeaders({});
					expect(result).toBeInstanceOf("core.baseSerializer");
				});

				it("should return empty struct when no headers set", function() {
					var result = serializer.getHeaders();
					expect(result).toBeStruct();
					expect(structIsEmpty(result)).toBeTrue();
				});

			});

			describe("noData()", function() {

				it("should return serializer instance when noDataSends204NoContent is false", function() {
					application._taffy.settings.noDataSends204NoContent = false;
					var result = serializer.noData();
					expect(result).toBeInstanceOf("core.baseSerializer");
				});

				it("should return 204 status when noDataSends204NoContent is true", function() {
					application._taffy.settings.noDataSends204NoContent = true;
					var result = serializer.noData();
					expect(result.getStatus()).toBe(204);
				});

			});

			describe("noContent()", function() {

				it("should set status to 204 No Content", function() {
					var result = serializer.noContent();
					expect(result.getStatus()).toBe(204);
					expect(result.getStatusText()).toBe("No Content");
				});

				it("should set Content-Type header to text/plain", function() {
					var result = serializer.noContent();
					var headers = result.getHeaders();
					expect(headers["Content-Type"]).toBe("text/plain");
				});

			});

			describe("File streaming methods", function() {

				describe("setFileName()", function() {

					it("should store filename for streaming", function() {
						serializer.setFileName("/path/to/file.pdf");
						expect(serializer.getFileName()).toBe("/path/to/file.pdf");
					});

					it("should set type to filename (2)", function() {
						serializer.setFileName("/path/to/file.pdf");
						expect(serializer.getType()).toBe("filename");
					});

					it("should return this for method chaining", function() {
						var result = serializer.setFileName("/path/to/file.pdf");
						expect(result).toBeInstanceOf("core.baseSerializer");
					});

				});

				describe("setFileData()", function() {

					it("should store binary data for streaming", function() {
						var binaryData = toBinary(toBase64("test data"));
						serializer.setFileData(binaryData);
						expect(serializer.getFileData()).toBe(binaryData);
					});

					it("should set type to filedata (3)", function() {
						serializer.setFileData(toBinary(toBase64("test")));
						expect(serializer.getType()).toBe("filedata");
					});

				});

				describe("setImageData()", function() {

					it("should store image data for streaming", function() {
						var imageData = toBinary(toBase64("fake image data"));
						serializer.setImageData(imageData);
						expect(serializer.getImageData()).notToBeNull();
					});

					it("should set type to imagedata (4)", function() {
						serializer.setImageData(toBinary(toBase64("test")));
						expect(serializer.getType()).toBe("imagedata");
					});

					it("should convert non-binary data to binary", function() {
						serializer.setImageData("test string");
						expect(isBinary(serializer.getImageData())).toBeTrue();
					});

				});

				describe("withMime()", function() {

					it("should set mime type for file streaming", function() {
						serializer.withMime("application/pdf");
						expect(serializer.getFileMime()).toBe("application/pdf");
					});

					it("should return this for method chaining", function() {
						var result = serializer.withMime("image/jpeg");
						expect(result).toBeInstanceOf("core.baseSerializer");
					});

				});

				describe("andDelete()", function() {

					it("should set delete flag to true", function() {
						serializer.andDelete(true);
						expect(serializer.getDeleteFile()).toBeTrue();
					});

					it("should set delete flag to false", function() {
						serializer.andDelete(false);
						expect(serializer.getDeleteFile()).toBeFalse();
					});

					it("should return this for method chaining", function() {
						var result = serializer.andDelete(true);
						expect(result).toBeInstanceOf("core.baseSerializer");
					});

				});

			});

			describe("Method chaining", function() {

				it("should support fluent interface for multiple operations", function() {
					var result = serializer
						.setData({ message: "test" })
						.withStatus(201, "Created")
						.withHeaders({ "X-Custom": "value" });

					expect(result.getData().message).toBe("test");
					expect(result.getStatus()).toBe(201);
					expect(result.getHeaders()["X-Custom"]).toBe("value");
				});

				it("should support chaining for file streaming", function() {
					var result = serializer
						.setFileName("/path/to/file.pdf")
						.withMime("application/pdf")
						.andDelete(true);

					expect(result.getFileName()).toBe("/path/to/file.pdf");
					expect(result.getFileMime()).toBe("application/pdf");
					expect(result.getDeleteFile()).toBeTrue();
				});

			});

		});

	}

}
