component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Build base URL from the server running these tests
		var port = cgi.server_port;
		var host = cgi.server_name;
		if (!len(host) || host == "") host = "localhost";
		variables.baseURL = "http://#host#:#port#/tests/testapi/index.cfm";
	}

	/**
	 * Helper: make an HTTP request to the test API
	 */
	private struct function apiRequest(
		required string uri,
		string method = "GET",
		string body = "",
		struct headers = {}
	) {
		var result = {};
		var fullURL = variables.baseURL & "?endpoint=" & arguments.uri;

		cfhttp(url=fullURL, method=arguments.method, result="result", timeout=10, charset="utf-8") {
			cfhttpparam(type="header", name="Content-Type", value="application/json");
			cfhttpparam(type="header", name="Accept", value="application/json");
			for (var h in arguments.headers) {
				cfhttpparam(type="header", name=h, value=arguments.headers[h]);
			}
			if (len(arguments.body)) {
				cfhttpparam(type="body", value=arguments.body);
			}
		}

		result.data = {};
		if (structKeyExists(result, "fileContent")) {
			var body = result.fileContent;
			if (!isSimpleValue(body)) {
				body = toString(body);
			}
			body = trim(body);
			if (len(body) && isJSON(body)) {
				result.data = deserializeJSON(body);
			}
		}
		return result;
	}

	function run() {

		describe("End-to-End HTTP Tests", function() {

			describe("GET requests", function() {

				it("should return 200 for a valid GET request", function() {
					var res = apiRequest("/echo");
					expect(res.status_code).toBe(200);
					expect(res.data.method).toBe("GET");
					expect(res.data.message).toBe("echo");
				});

				it("should extract URI token from path", function() {
					var res = apiRequest("/echo/42");
					expect(res.status_code).toBe(200);
					expect(res.data.id).toBe("42");
					expect(res.data.method).toBe("GET");
				});

				it("should extract multiple URI tokens", function() {
					var res = apiRequest("/echo/10/child/20");
					expect(res.status_code).toBe(200);
					expect(res.data.parentId).toBe("10");
					expect(res.data.childId).toBe("20");
				});

				it("should return JSON content type", function() {
					var res = apiRequest("/echo");
					expect(res.responseheader["Content-Type"]).toInclude("application/json");
				});

			});

			describe("POST requests", function() {

				it("should return 201 Created", function() {
					var res = apiRequest(
						uri = "/echo",
						method = "POST",
						body = '{"name":"test","value":"123"}'
					);
					expect(res.status_code).toBe(201);
					expect(res.data.method).toBe("POST");
				});

				it("should deserialize JSON request body", function() {
					var res = apiRequest(
						uri = "/echo",
						method = "POST",
						body = '{"name":"widget","value":"abc"}'
					);
					expect(res.data.name).toBe("widget");
					expect(res.data.value).toBe("abc");
				});

			});

			describe("PUT requests", function() {

				it("should handle PUT with URI token and body", function() {
					var res = apiRequest(
						uri = "/echo/55",
						method = "PUT",
						body = '{"name":"updated"}'
					);
					expect(res.status_code).toBe(200);
					expect(res.data.method).toBe("PUT");
					expect(res.data.id).toBe("55");
					expect(res.data.name).toBe("updated");
				});

			});

			describe("DELETE requests", function() {

				it("should handle DELETE with URI token", function() {
					var res = apiRequest(uri="/echo/99", method="DELETE");
					expect(res.status_code).toBe(200);
					expect(res.data.method).toBe("DELETE");
					expect(res.data.id).toBe("99");
				});

				it("should return custom response headers", function() {
					var res = apiRequest(uri="/echo/99", method="DELETE");
					expect(res.responseheader["X-Deleted-Id"]).toBe("99");
				});

			});

			describe("Error responses", function() {

				it("should return 404 for unknown URI", function() {
					var res = apiRequest("/nonexistent/path");
					expect(res.status_code).toBe(404);
				});

				it("should return 405 for unsupported HTTP method", function() {
					// /echo/{parentId}/child/{childId} only supports GET
					var res = apiRequest(uri="/echo/1/child/2", method="DELETE");
					expect(res.status_code).toBe(405);
				});

			});

			describe("X-HTTP-Method-Override", function() {

				it("should support method tunneling via header", function() {
					var res = apiRequest(
						uri = "/echo/77",
						method = "POST",
						headers = { "X-HTTP-Method-Override": "PUT" },
						body = '{"name":"tunneled"}'
					);
					expect(res.data.method).toBe("PUT");
					expect(res.data.id).toBe("77");
					expect(res.data.name).toBe("tunneled");
				});

			});

		});

	}

}
