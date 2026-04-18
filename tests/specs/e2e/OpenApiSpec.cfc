component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		var port = cgi.server_port;
		var host = cgi.server_name;
		if (!len(host) || host == "") host = "localhost";
		variables.baseURL = "http://#host#:#port#/tests/testapi/index.cfm";
	}

	private struct function fetchSpec(string param = "openapi") {
		var result = {};
		cfhttp(url="#variables.baseURL#?#arguments.param#", method="GET", result="result", timeout=10, charset="utf-8");
		return result;
	}

	function run() {

		describe("OpenAPI 3.1 spec endpoint", function() {

			it("returns JSON with openapi version 3.1.0", function() {
				var res = fetchSpec("openapi");
				expect(res.status_code).toBe(200);
				expect(isJSON(res.fileContent)).toBeTrue("Expected JSON, got: " & left(res.fileContent, 300));
				var spec = deserializeJSON(res.fileContent);
				expect(spec.openapi).toBe("3.1.0");
			});

			it("includes info.title and info.version", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				expect(spec).toHaveKey("info");
				expect(spec.info).toHaveKey("title");
				expect(spec.info).toHaveKey("version");
			});

			it("documents /echo/{id} with GET, PUT, DELETE", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				expect(spec).toHaveKey("paths");
				expect(spec.paths).toHaveKey("/echo/{id}");
				var echo = spec.paths["/echo/{id}"];
				expect(echo).toHaveKey("get");
				expect(echo).toHaveKey("put");
				expect(echo).toHaveKey("delete");
			});

			it("marks path token 'id' as required in:path on GET", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				var params = spec.paths["/echo/{id}"].get.parameters;
				var found = false;
				for (var i = 1; i <= arrayLen(params); i++) {
					if (params[i].name == "id" && params[i]["in"] == "path" && params[i].required == true) {
						found = true;
						break;
					}
				}
				expect(found).toBeTrue("Expected required path parameter 'id' on GET /echo/{id}");
			});

			it("emits requestBody with json + form-urlencoded for PUT body params", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				var put = spec.paths["/echo/{id}"].put;
				expect(put).toHaveKey("requestBody");
				expect(put.requestBody.content).toHaveKey("application/json");
				expect(put.requestBody.content).toHaveKey("application/x-www-form-urlencoded");
				var props = put.requestBody.content["application/json"].schema.properties;
				expect(props).toHaveKey("name");
			});

			it("includes responses.200 for each operation", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				expect(spec.paths["/echo/{id}"].get).toHaveKey("responses");
				expect(spec.paths["/echo/{id}"].get.responses).toHaveKey("200");
			});

			it("accepts ?swagger alias", function() {
				var res = fetchSpec("swagger");
				expect(res.status_code).toBe(200);
				expect(deserializeJSON(res.fileContent).openapi).toBe("3.1.0");
			});

		});

	}

}
