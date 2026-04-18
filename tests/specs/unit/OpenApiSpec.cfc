component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.gen = new core.openapi();
		makePublic(variables.gen, "normalizePathTemplate");
		makePublic(variables.gen, "cfmlTypeToSchema");
		makePublic(variables.gen, "buildOperation");
	}

	function run() {

		describe("openapi generator", function() {

			describe("normalizePathTemplate", function() {

				it("leaves simple paths untouched", function() {
					expect(gen.normalizePathTemplate("/users", [])).toBe("/users");
				});

				it("leaves {name} tokens untouched", function() {
					expect(gen.normalizePathTemplate("/users/{id}", ["id"])).toBe("/users/{id}");
				});

				it("strips {name:regex} down to {name}", function() {
					expect(gen.normalizePathTemplate("/users/{id:[0-9]+}", ["id"])).toBe("/users/{id}");
				});

				it("strips greedy regex like {name:.+}", function() {
					expect(gen.normalizePathTemplate("/files/{path:.+}", ["path"])).toBe("/files/{path}");
				});

				it("handles nested braces in token regexes", function() {
					expect(gen.normalizePathTemplate("/a/{b:[a-z]+(?:42){1}}", ["b"])).toBe("/a/{b}");
				});

				it("rewrites multiple tokens in order", function() {
					expect(gen.normalizePathTemplate("/events/{eventId:\d+}/attendees/{personId}", ["eventId", "personId"]))
						.toBe("/events/{eventId}/attendees/{personId}");
				});

			});

			describe("cfmlTypeToSchema", function() {

				it("maps numeric to number", function() {
					expect(gen.cfmlTypeToSchema("numeric")).toBe({ "type": "number" });
				});

				it("maps boolean to boolean", function() {
					expect(gen.cfmlTypeToSchema("boolean")).toBe({ "type": "boolean" });
				});

				it("maps date to string/date-time", function() {
					expect(gen.cfmlTypeToSchema("date")).toBe({ "type": "string", "format": "date-time" });
				});

				it("maps uuid to string/uuid", function() {
					expect(gen.cfmlTypeToSchema("uuid")).toBe({ "type": "string", "format": "uuid" });
				});

				it("returns empty schema for 'any'", function() {
					expect(gen.cfmlTypeToSchema("any")).toBe({});
				});

				it("returns empty schema for unset type", function() {
					expect(gen.cfmlTypeToSchema("")).toBe({});
				});

			});

			describe("buildOperation — path param handling", function() {

				// minimal fixtures
				var mkEndpoint = function(beanName, srcUri, tokens, methods) {
					return { beanName: beanName, srcUri: srcUri, tokens: tokens, methods: methods };
				};
				var mkFunc = function(name, parameters = []) {
					return { name: name, parameters: parameters };
				};

				it("backfills path tokens not declared as function args", function() {
					var endpoint = mkEndpoint("MyResource", "/items/{id}", ["id"], { get: "get" });
					var func = mkFunc("get", []); // function declares NO args
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"]);

					expect(op).toHaveKey("parameters");
					expect(arrayLen(op.parameters)).toBe(1);
					expect(op.parameters[1].name).toBe("id");
					expect(op.parameters[1]["in"]).toBe("path");
					expect(op.parameters[1].required).toBeTrue();
				});

				it("uses token's original case when arg casing differs", function() {
					var endpoint = mkEndpoint("AttendeesResource", "/attendees/{personId}", ["personId"], { put: "put" });
					// simulate CFML metadata that lowercased the arg name
					var func = mkFunc("put", [ { name: "personid", type: "numeric", required: true } ]);
					var op = gen.buildOperation("put", func, endpoint, {}, ["application/json"]);

					expect(op.parameters[1].name).toBe("personId");
					expect(op.parameters[1]["in"]).toBe("path");
					expect(op.parameters[1].schema).toBe({ "type": "number" });
				});

				it("puts non-token args for GET into query", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", [ { name: "limit", type: "numeric", required: false } ]);
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"]);

					expect(op.parameters[1].name).toBe("limit");
					expect(op.parameters[1]["in"]).toBe("query");
					expect(op.parameters[1].required).toBeFalse();
				});

				it("puts non-token args for POST into requestBody with both json + form", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { post: "post" });
					var func = mkFunc("post", [ { name: "name", type: "string", required: true } ]);
					var op = gen.buildOperation("post", func, endpoint, {}, ["application/json"]);

					expect(op).toHaveKey("requestBody");
					expect(op.requestBody.content).toHaveKey("application/json");
					expect(op.requestBody.content).toHaveKey("application/x-www-form-urlencoded");
					expect(op.requestBody.content["application/json"].schema.properties).toHaveKey("name");
					expect(op.requestBody.content["application/json"].schema.required).toBe(["name"]);
				});

			});

		});

	}

}
