component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.gen = new core.openapi();
		makePublic(variables.gen, "normalizePathTemplate");
		makePublic(variables.gen, "cfmlTypeToSchema");
		makePublic(variables.gen, "buildOperation");
		makePublic(variables.gen, "deepMergeStructs");
		makePublic(variables.gen, "mergeParameters");
		makePublic(variables.gen, "normalizeOpenApiDocKeys");
		variables.provider = new tests.fixtures.OpenApiProviderFixture();
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
				var mkFuncs = function(bean) {
					var funcs = {};
					var meta = getMetaData(arguments.bean);
					for (var i = 1; i <= arrayLen(meta.functions); i++) {
						funcs[meta.functions[i].name] = meta.functions[i];
					}
					return funcs;
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

				it("coerces generated schema defaults to matching primitive types", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", [
						{ name: "active", type: "boolean", required: false, default: "true" },
						{ name: "limit", type: "integer", required: false, default: "10" },
						{ name: "score", type: "numeric", required: false, default: "2.5" }
					]);
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"]);

					expect(op.parameters[1].schema.default).toBeTrue();
					expect(op.parameters[2].schema.default).toBe(10);
					expect(op.parameters[3].schema.default).toBe(2.5);
				});

				it("uses provider response defaults instead of assuming a 200 response", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", []);
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"]);

					expect(op.responses).toHaveKey("default");
					expect(op.responses.default.description).toBe("Response not documented.");
					expect(structKeyExists(op.responses, "200")).toBeFalse();
				});

				it("applies provider exclusions to generated query parameters", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", [
						{ name: "limit", type: "numeric", required: false },
						{ name: "internalContext", type: "struct", required: false }
					]);
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"], provider);

					expect(arrayLen(op.parameters)).toBe(2);
					expect(op.parameters[1].name).toBe("limit");
					expect(op.parameters[2].name).toBe("X-Trace-Id");
					expect(op.responses.default.description).toBe("Fixture default response.");
				});

				it("fills operation descriptions when neither metadata nor endpoint docs provide one", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", []);
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"]);

					expect(op.description).toBe(op.operationId);
				});

				it("marks operations deprecated for accepted true metadata values", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", []);
					var op = gen.buildOperation("get", func, endpoint, { "taffy_deprecated": "yes" }, ["application/json"]);

					expect(op.deprecated).toBeTrue();
				});

				it("does not treat on as deprecated metadata", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					endpoint.deprecated = "on";
					var func = mkFunc("get", []);
					func["taffy_deprecated"] = "on";
					var op = gen.buildOperation("get", func, endpoint, { "taffy_deprecated": "on" }, ["application/json"]);

					expect(structKeyExists(op, "deprecated")).toBeFalse();
				});

				it("applies provider exclusions to generated request body properties", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { post: "post" });
					var func = mkFunc("post", [
						{ name: "name", type: "string", required: true },
						{ name: "internalContext", type: "struct", required: true }
					]);
					var op = gen.buildOperation("post", func, endpoint, {}, ["application/json"], provider);
					var schema = op.requestBody.content["application/json"].schema;

					expect(schema.properties).toHaveKey("name");
					expect(structKeyExists(schema.properties, "internalContext")).toBeFalse();
					expect(schema.required).toBe(["name"]);
				});

				it("merges endpoint docs responses and lets endpoint parameters override globals", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "get" });
					var func = mkFunc("get", []);
					var bean = new tests.fixtures.OpenApiDocsResourceFixture();
					var op = gen.buildOperation("get", func, endpoint, {}, ["application/json"], provider, bean, mkFuncs(bean));

					expect(op.responses).toHaveKey("default");
					expect(op.responses).toHaveKey("404");
					expect(arrayLen(op.parameters)).toBe(1);
					expect(op.parameters[1].name).toBe("X-Trace-Id");
					expect(op.parameters[1].description).toBe("Endpoint trace header.");
				});

				it("merges endpoint request body examples", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { post: "post" });
					var func = mkFunc("post", [ { name: "name", type: "string", required: true } ]);
					var bean = new tests.fixtures.OpenApiDocsResourceFixture();
					var op = gen.buildOperation("post", func, endpoint, {}, ["application/json"], provider, bean, mkFuncs(bean));

					expect(op.requestBody.content["application/json"].schema.properties).toHaveKey("name");
					expect(op.requestBody.content["application/json"].examples.sample.value.name).toBe("Ada");
					expect(op.responses).toHaveKey("201");
				});

				it("normalizes endpoint docs OpenAPI keyword casing and preserves map keys", function() {
					var normalized = gen.normalizeOpenApiDocKeys({
						"operationid": "customOperation",
						"requestbody": {
							"content": {
								"application/json": {
									"schema": {
										"type": "object",
										"additionalproperties": { "type": "string" },
										"properties": {
											"CamelCaseProperty": {
												"readonly": true,
												"writeonly": false
											}
										}
									}
								}
							}
						},
						"responses": {
							"DEFAULT": { "description": "Fallback." },
							"200": { "description": "OK." }
						}
					});

					expect(normalized).toHaveKey("operationId");
					expect(normalized).toHaveKey("requestBody");
					expect(normalized.requestBody.content).toHaveKey("application/json");
					expect(normalized.requestBody.content["application/json"].schema).toHaveKey("additionalProperties");
					expect(normalized.requestBody.content["application/json"].schema.properties).toHaveKey("CamelCaseProperty");
					expect(normalized.requestBody.content["application/json"].schema.properties["CamelCaseProperty"]).toHaveKey("readOnly");
					expect(normalized.requestBody.content["application/json"].schema.properties["CamelCaseProperty"]).toHaveKey("writeOnly");
					expect(normalized.responses).toHaveKey("default");
					expect(normalized.responses).toHaveKey("200");
				});

				it("discovers docs for custom taffy_verb resource methods by function name", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items/{id}", ["id"], { patch: "updatePartial" });
					var func = mkFunc("updatePartial", [ { name: "id", type: "string", required: true } ]);
					var bean = new tests.fixtures.OpenApiDocsResourceFixture();
					var op = gen.buildOperation("patch", func, endpoint, {}, ["application/json"], provider, bean, mkFuncs(bean));

					expect(op.responses).toHaveKey("202");
				});

				it("throws a clear error when endpoint docs do not return a struct", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "bad" });
					var func = mkFunc("bad", []);
					var bean = new tests.fixtures.OpenApiDocsResourceFixture();

					expect(function() {
						gen.buildOperation("get", func, endpoint, {}, ["application/json"], provider, bean, mkFuncs(bean));
					}).toThrow();
				});

				it("throws a clear error when endpoint docs have required arguments", function() {
					var endpoint = mkEndpoint("ItemsResource", "/items", [], { get: "required" });
					var func = mkFunc("required", []);
					var bean = new tests.fixtures.OpenApiDocsResourceFixture();

					expect(function() {
						gen.buildOperation("get", func, endpoint, {}, ["application/json"], provider, bean, mkFuncs(bean));
					}).toThrow();
				});

			});

			describe("generate", function() {

				it("adds default info description and contact when not configured", function() {
					var savedTaffy = duplicate(application._taffy);
					try {
						application._taffy = {
							settings: {
								docs: { APIName: "Fixture", APIVersion: "1.0.0" },
								openapi: {},
								mimeExtensions: { json: "application/json" }
							},
							endpoints: {},
							uriMatchOrder: [],
							openapiProvider: new core.openapiProvider()
						};

						var spec = gen.generate();

						expect(spec.info.description).toBe("Fixture OpenAPI specification.");
						expect(spec.info.contact.name).toBe("Fixture");
					} finally {
						application._taffy = savedTaffy;
					}
				});

				it("adds provider components and returns the provider final hook result", function() {
					var savedTaffy = duplicate(application._taffy);
					try {
						application._taffy = {
							settings: {
								docs: { APIName: "Fixture", APIVersion: "1.0.0" },
								openapi: {
									description: "Fixture API",
									contact: { email: "api@example.com" },
									license: { name: "MIT" },
									servers: [ { url: "https://api.example.com" } ]
								},
								mimeExtensions: { json: "application/json" }
							},
							endpoints: {},
							uriMatchOrder: [],
							openapiProvider: provider
						};

						var spec = gen.generate();

						expect(spec.info.description).toBe("Fixture API");
						expect(spec.info.contact.email).toBe("api@example.com");
						expect(spec.info.license.name).toBe("MIT");
						expect(spec.servers[1].url).toBe("https://api.example.com");
						expect(spec.components.schemas).toHaveKey("Fixture");
						expect(spec["x-fixture-afterGenerate"]).toBeTrue();
					} finally {
						application._taffy = savedTaffy;
					}
				});

				it("returns source map entries with generated operations", function() {
					var savedTaffy = duplicate(application._taffy);
					try {
						application._taffy = {
							settings: {
								docs: { APIName: "Fixture", APIVersion: "1.0.0" },
								openapi: {},
								mimeExtensions: { json: "application/json" }
							},
							endpoints: {
								"^/items/([^/]+)$": {
									beanName: "tests.fixtures.OpenApiDocsResourceFixture",
									srcUri: "/items/{id}",
									tokens: [ "id" ],
									methods: { get: "get" }
								}
							},
							uriMatchOrder: [ "^/items/([^/]+)$" ],
							factory: {
								getBean: function(beanName) {
									return new tests.fixtures.OpenApiDocsResourceFixture();
								}
							},
							openapiProvider: provider
						};

						var generated = gen.generateWithSourceMap();

						expect(generated).toHaveKey("spec");
						expect(generated).toHaveKey("sourceMap");
						expect(generated.spec).toHaveKey("tags");
						expect(generated.spec.tags[1].name).toBe("tests.fixtures.OpenApiDocsResourceFixture");
						expect(generated.sourceMap).toHaveKey("/paths/~1items~1{id}/get");
						expect(generated.sourceMap["/paths/~1items~1{id}/get"].docsMethod).toBe("getOpenAPIDocs");
						expect(generated.sourceMap["/paths/~1items~1{id}/get"].operation).toBe("GET /items/{id}");
					} finally {
						application._taffy = savedTaffy;
					}
				});

				it("throws a clear error when provider afterGenerate does not return a struct", function() {
					var savedTaffy = duplicate(application._taffy);
					try {
						application._taffy = {
							settings: {
								docs: { APIName: "Fixture", APIVersion: "1.0.0" },
								openapi: {},
								mimeExtensions: { json: "application/json" }
							},
							endpoints: {},
							uriMatchOrder: [],
							openapiProvider: new tests.fixtures.BadAfterGenerateProvider()
						};

						expect(function() {
							gen.generate();
						}).toThrow();
					} finally {
						application._taffy = savedTaffy;
					}
				});

			});

			describe("merge helpers", function() {

				it("deep-merges nested structs and replaces ordinary arrays", function() {
					var merged = gen.deepMergeStructs(
						{
							"responses": {
								"default": {
									"description": "Response not documented.",
									"content": { "application/json": { "schema": {} } }
								}
							},
							"tags": [ "generated" ]
						},
						{
							"responses": {
								"default": {
									"description": "Documented default."
								},
								"404": { "description": "Not found." }
							},
							"tags": [ "endpoint" ]
						}
					);

					expect(merged.responses.default.description).toBe("Documented default.");
					expect(merged.responses.default.content["application/json"].schema).toBe({});
					expect(merged.responses).toHaveKey("404");
					expect(merged.tags).toBe([ "endpoint" ]);
				});

				it("merges parameters by case-insensitive location and name", function() {
					var merged = gen.mergeParameters(
						[
							{ "name": "X-Trace-Id", "in": "header", "description": "global" },
							{ "name": "limit", "in": "query" }
						],
						[
							{ "name": "x-trace-id", "in": "HEADER", "description": "endpoint" },
							{ "name": "offset", "in": "query" }
						]
					);

					expect(arrayLen(merged)).toBe(3);
					expect(merged[1].description).toBe("endpoint");
					expect(merged[3].name).toBe("offset");
				});

			});

		});

	}

}
