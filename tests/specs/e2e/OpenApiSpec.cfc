component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		var port = cgi.server_port;
		var host = cgi.server_name;
		if (!len(host) || host == "") host = "localhost";
		variables.baseURL = "http://#host#:#port#/tests/testapi/index.cfm";
		variables.lintDisabledURL = "http://#host#:#port#/tests/lintdisabledapi/index.cfm";
		variables.openapiDisabledURL = "http://#host#:#port#/tests/openapidisabledapi/index.cfm";
	}

	private struct function fetchSpec(string param = "openapi") {
		var result = {};
		cfhttp(url="#variables.baseURL#?#arguments.param#", method="GET", result="result", timeout=10, charset="utf-8");
		return result;
	}

	private struct function fetchUrl(required string url, required string param) {
		var result = {};
		cfhttp(url="#arguments.url#?#arguments.param#", method="GET", result="result", timeout=10, charset="utf-8");
		return result;
	}

	private struct function apiRequest(required string uri) {
		var result = {};
		cfhttp(url="#variables.baseURL#?endpoint=#arguments.uri#", method="GET", result="result", timeout=10, charset="utf-8") {
			cfhttpparam(type="header", name="Accept", value="application/json");
		}
		result.data = {};
		if (structKeyExists(result, "fileContent") && isJSON(result.fileContent)) {
			result.data = deserializeJSON(result.fileContent);
		}
		return result;
	}

	private boolean function hasIssue(required struct lint, required string code) {
		for (var i = 1; i <= arrayLen(arguments.lint.issues); i++) {
			if (arguments.lint.issues[i].code == arguments.code) {
				return true;
			}
		}
		return false;
	}

	private struct function issueByCode(required struct lint, required string code) {
		for (var i = 1; i <= arrayLen(arguments.lint.issues); i++) {
			if (arguments.lint.issues[i].code == arguments.code) {
				return arguments.lint.issues[i];
			}
		}
		return {};
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

			it("uses honest default responses for undocumented operations", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				var responses = spec.paths["/echo/{id}"].delete.responses;

				expect(responses).toHaveKey("default");
				expect(responses.default.description).toBe("Response not documented.");
				expect(structKeyExists(responses, "200")).toBeFalse();
			});

			it("merges endpoint OpenAPI docs into the generated operation", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				var get = spec.paths["/echo/{id}"].get;

				expect(get.summary).toBe("Fetch echo");
				expect(get.responses).toHaveKey("default");
				expect(get.responses).toHaveKey("200");
				expect(get.responses["200"].content["application/json"].schema["$ref"]).toBe("##/components/schemas/Echo");
			});

			it("adds provider components and runs the final provider hook", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);

				expect(spec.components.schemas).toHaveKey("Echo");
				expect(spec["x-provider-afterGenerate"]).toBeTrue();
			});

			it("applies provider exclusions and global parameters", function() {
				var spec = deserializeJSON(fetchSpec().fileContent);
				var getParams = spec.paths["/echo/{id}"].get.parameters;
				var putSchema = spec.paths["/echo/{id}"].put.requestBody.content["application/json"].schema;
				var traceCount = 0;
				var traceDescription = "";

				for (var i = 1; i <= arrayLen(getParams); i++) {
					expect(getParams[i].name).notToBe("internalContext");
					if (getParams[i].name == "X-Trace-Id" && getParams[i]["in"] == "header") {
						traceCount++;
						traceDescription = getParams[i].description;
					}
				}

				expect(traceCount).toBe(1);
				expect(traceDescription).toBe("Endpoint trace header.");
				expect(structKeyExists(putSchema.properties, "internalContext")).toBeFalse();
			});

			it("serves the cached serialized spec without rerunning the provider", function() {
				var first = deserializeJSON(fetchSpec("openapi&reload=true").fileContent);
				var second = deserializeJSON(fetchSpec().fileContent);

				expect(second["x-provider-afterGenerate-count"]).toBe(first["x-provider-afterGenerate-count"]);
			});

			it("reload invalidates the cached spec and creates a new provider instance", function() {
				var first = deserializeJSON(fetchSpec("openapi&reload=true").fileContent);
				var second = deserializeJSON(fetchSpec("openapi&reload=true").fileContent);

				expect(second["x-provider-instance-id"]).notToBe(first["x-provider-instance-id"]);
			});

			it("accepts ?swagger alias", function() {
				var res = fetchSpec("swagger");
				expect(res.status_code).toBe(200);
				expect(deserializeJSON(res.fileContent).openapi).toBe("3.1.0");
			});

		});

		describe("OpenAPI lint endpoint", function() {

			it("returns JSON diagnostics from ?openapiLint", function() {
				var res = fetchSpec("openapiLint&reload=true");

				expect(res.status_code).toBe(200);
				expect(isJSON(res.fileContent)).toBeTrue("Expected JSON, got: " & left(res.fileContent, 300));

				var lint = deserializeJSON(res.fileContent);
				expect(lint).toHaveKey("valid");
				expect(lint).toHaveKey("summary");
				expect(lint).toHaveKey("issues");
			});

			it("accepts ?swaggerLint alias", function() {
				var res = fetchSpec("swaggerLint");
				var lint = deserializeJSON(res.fileContent);

				expect(res.status_code).toBe(200);
				expect(lint).toHaveKey("valid");
				expect(lint).toHaveKey("summary");
				expect(lint).toHaveKey("issues");
			});

			it("returns 403 when linting is disabled by default", function() {
				var res = fetchUrl(variables.lintDisabledURL, "openapiLint&reload=true");

				expect(res.status_code).toBe(403);
			});

			it("returns 403 when OpenAPI is disabled", function() {
				var res = fetchUrl(variables.openapiDisabledURL, "openapiLint&reload=true");

				expect(res.status_code).toBe(403);
			});

			it("reports expected warnings and infos for the test API", function() {
				var lint = deserializeJSON(fetchSpec("openapiLint&reload=true").fileContent);

				expect(lint.summary.warnings).toBeGT(0);
				expect(lint.summary.info).toBeGT(0);
				expect(hasIssue(lint, "operation.responses.onlyDefault")).toBeTrue();
				expect(hasIssue(lint, "response.default.undocumented")).toBeTrue();
			});

			it("does not report schema-missing warnings for documented response schemas", function() {
				var lint = deserializeJSON(fetchSpec("openapiLint&reload=true").fileContent);
				var foundMissingEchoSchema = false;

				for (var i = 1; i <= arrayLen(lint.issues); i++) {
					if (
						lint.issues[i].code == "response.content.schema.missing"
						&& find("/paths/~1echo~1{id}/get/responses/200/", lint.issues[i].path)
					) {
						foundMissingEchoSchema = true;
						break;
					}
				}

				expect(foundMissingEchoSchema).toBeFalse();
			});

			it("reports broken fixture refs", function() {
				var lint = deserializeJSON(fetchSpec("openapiLint&reload=true").fileContent);

				expect(hasIssue(lint, "schema.ref.broken")).toBeTrue();
				expect(lint.valid).toBeFalse();
			});

			it("does not invoke real resource responder methods", function() {
				fetchSpec("openapiLint&reload=true");
				var state = apiRequest("/openapi-lint-state");

				expect(state.status_code).toBe(200);
				expect(state.data.brokenResourceInvoked).toBe(0);
			});

			it("reuses a cached spec when linting", function() {
				var first = deserializeJSON(fetchSpec("openapi&reload=true").fileContent);
				fetchSpec("openapiLint");
				var second = deserializeJSON(fetchSpec("openapi").fileContent);

				expect(second["x-provider-afterGenerate-count"]).toBe(first["x-provider-afterGenerate-count"]);
			});

			it("populates the cached spec when linting first", function() {
				var before = deserializeJSON(fetchSpec("openapi&reload=true").fileContent);
				fetchSpec("openapiLint&reload=true");
				var after = deserializeJSON(fetchSpec("openapi").fileContent);

				expect(after["x-provider-afterGenerate-count"]).toBe(before["x-provider-afterGenerate-count"] + 1);
			});

			it("adds friendly source-map locations to operation issues", function() {
				var lint = deserializeJSON(fetchSpec("openapiLint&reload=true").fileContent);
				var issue = issueByCode(lint, "response.default.undocumented");

				expect(structIsEmpty(issue)).toBeFalse();
				expect(issue).toHaveKey("location");
				expect(issue.location).toHaveKey("operation");
				expect(issue.location).toHaveKey("target");
			});

		});

	}

}
