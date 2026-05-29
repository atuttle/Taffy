component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.provider = new core.openapiProvider();
	}

	function run() {

		describe("OpenAPI provider defaults", function() {

			it("returns no components by default", function() {
				expect(provider.getComponents()).toBe({});
			});

			it("returns no global parameters by default", function() {
				expect(provider.getGlobalParameters()).toBe([]);
			});

			it("returns no excluded parameters by default", function() {
				expect(provider.getExcludeParameters()).toBe([]);
			});

			it("returns the same spec from afterGenerate by default", function() {
				var spec = { "openapi": "3.1.0", "paths": {} };
				expect(provider.afterGenerate(spec)).toBe(spec);
			});

			it("returns an undocumented default response with media types", function() {
				var responses = provider.getResponseDefaults(["application/json"]);

				expect(responses).toHaveKey("default");
				expect(responses.default.description).toBe("Response not documented.");
				expect(structKeyExists(responses, "200")).toBeFalse();
				expect(responses.default.content["application/json"].schema).toBe({});
			});

			it("omits response content when media types are empty", function() {
				var responses = provider.getResponseDefaults([]);

				expect(responses).toHaveKey("default");
				expect(responses.default.description).toBe("Response not documented.");
				expect(structKeyExists(responses.default, "content")).toBeFalse();
			});

		});

	}

}
