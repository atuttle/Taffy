component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.linter = new core.openapiLinter();
	}

	private struct function operationSpec(required struct operation, string pathName = "/things", string verb = "get") {
		var spec = {
			openapi = "3.1.0",
			info = { title = "Test", version = "1.0.0" },
			paths = {}
		};
		spec.paths[arguments.pathName] = {};
		spec.paths[arguments.pathName][arguments.verb] = arguments.operation;
		return spec;
	}

	private boolean function hasIssue(required struct result, required string code) {
		for (var i = 1; i <= arrayLen(arguments.result.issues); i++) {
			if (arguments.result.issues[i].code == arguments.code) {
				return true;
			}
		}
		return false;
	}

	private struct function issueByCode(required struct result, required string code) {
		for (var i = 1; i <= arrayLen(arguments.result.issues); i++) {
			if (arguments.result.issues[i].code == arguments.code) {
				return arguments.result.issues[i];
			}
		}
		return {};
	}

	function run() {

		describe("OpenAPI linter", function() {

			it("returns valid=true for an empty spec", function() {
				var result = linter.lint({});

				expect(result.valid).toBeTrue();
				expect(result.summary.errors).toBe(0);
				expect(arrayLen(result.issues)).toBe(0);
			});

			it("reports missing operation responses as an error", function() {
				var result = linter.lint(operationSpec({ operationId = "listThings" }));

				expect(result.valid).toBeFalse();
				expect(hasIssue(result, "operation.responses.missing")).toBeTrue();
			});

			it("reports operations with only a default response", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						default = { description = "Response not documented." }
					}
				}));

				expect(hasIssue(result, "operation.responses.onlyDefault")).toBeTrue();
			});

			it("reports missing operationId", function() {
				var result = linter.lint(operationSpec({
					responses = {
						"200" = { description = "OK" }
					}
				}));

				expect(hasIssue(result, "operation.operationId.missing")).toBeTrue();
			});

			it("reports response content without schema", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {}
							}
						}
					}
				}));

				expect(hasIssue(result, "response.content.schema.missing")).toBeTrue();
			});

			it("reports request body content without schema", function() {
				var result = linter.lint(operationSpec({
					operationId = "createThing",
					requestBody = {
						content = {
							"application/json" = {}
						}
					},
					responses = {
						"201" = { description = "Created" }
					}
				}, "/things", "post"));

				expect(hasIssue(result, "requestBody.schema.missing")).toBeTrue();
			});

			it("reports request bodies without content", function() {
				var result = linter.lint(operationSpec({
					operationId = "createThing",
					requestBody = {},
					responses = {
						"201" = { description = "Created" }
					}
				}, "/things", "post"));

				expect(hasIssue(result, "requestBody.content.missing")).toBeTrue();
			});

			it("reports response without description", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {}
					}
				}));

				expect(hasIssue(result, "response.description.missing")).toBeTrue();
			});

			it("reports duplicate parameters by same location and name", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					parameters = [
						{ name = "limit", "in" = "query", schema = { type = "integer" } },
						{ name = "LIMIT", "in" = "query", schema = { type = "integer" } }
					],
					responses = {
						"200" = { description = "OK" }
					}
				}));

				expect(hasIssue(result, "parameter.duplicate")).toBeTrue();
			});

			it("reports path parameters with required=false", function() {
				var result = linter.lint(operationSpec({
					operationId = "getThing",
					parameters = [
						{ name = "id", "in" = "path", required = false, schema = { type = "string" } }
					],
					responses = {
						"200" = { description = "OK" }
					}
				}, "/things/{id}"));

				expect(hasIssue(result, "parameter.path.requiredFalse")).toBeTrue();
			});

			it("reports path tokens without matching path parameters", function() {
				var result = linter.lint(operationSpec({
					operationId = "getThing",
					parameters = [],
					responses = {
						"200" = { description = "OK" }
					}
				}, "/things/{id}"));

				expect(hasIssue(result, "path.parameter.missing")).toBeTrue();
			});

			it("reports auto-documented path tokens that handlers do not declare", function() {
				var result = linter.lint(
					operationSpec({
						operationId = "getThing",
						parameters = [
							{ name = "id", "in" = "path", required = true, schema = { type = "string" } }
						],
						responses = {
							"200" = { description = "OK" }
						}
					}, "/things/{id}"),
					{
						sourceMap = {
							"/paths/~1things~1{id}/get" = {
								resource = "ThingsResource",
								method = "get",
								docsMethod = "getOpenAPIDocs",
								operation = "GET /things/{id}",
								undeclaredPathTokens = [ "id" ]
							}
						}
					}
				);

				expect(hasIssue(result, "path.token.undeclaredHandler")).toBeTrue();
			});

			it("reports parameters without schema, content, or ref", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					parameters = [
						{ name = "limit", "in" = "query" }
					],
					responses = {
						"200" = { description = "OK" }
					}
				}));

				expect(hasIssue(result, "parameter.schema.missing")).toBeTrue();
			});

			it("reports broken local refs", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {
									schema = { "$ref" = "##/components/schemas/Missing" }
								}
							}
						}
					}
				}));

				expect(hasIssue(result, "schema.ref.broken")).toBeTrue();
			});

			it("does not report valid local refs as broken", function() {
				var spec = operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {
									schema = { "$ref" = "##/components/schemas/Thing" }
								}
							}
						}
					}
				});
				spec.components = {
					schemas = {
						Thing = { type = "object" }
					}
				};

				var result = linter.lint(spec);

				expect(hasIssue(result, "schema.ref.broken")).toBeFalse();
			});

			it("reports external refs as unchecked info", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {
									schema = { "$ref" = "https://example.com/schemas/Thing.json" }
								}
							}
						}
					}
				}));

				expect(hasIssue(result, "schema.ref.external")).toBeTrue();
			});

			it("handles recursive local refs without looping forever", function() {
				var spec = {
					components = {
						schemas = {
							Node = {
								type = "object",
								properties = {
									child = { "$ref" = "##/components/schemas/Node" }
								}
							}
						}
					}
				};

				var result = linter.lint(spec);

				expect(hasIssue(result, "schema.ref.broken")).toBeFalse();
				expect(hasIssue(result, "schema.traversal.maxDepth")).toBeFalse();
			});

			it("reports max schema traversal depth", function() {
				var schema = { type = "object", properties = {} };
				var cursor = schema;
				for (var i = 1; i <= 55; i++) {
					cursor.properties["p" & i] = { type = "object", properties = {} };
					cursor = cursor.properties["p" & i];
				}
				var result = linter.lint({
					components = {
						schemas = {
							Deep = schema
						}
					}
				});

				expect(hasIssue(result, "schema.traversal.maxDepth")).toBeTrue();
			});

			it("lints components.schemas directly", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Event = { type = "array" }
						}
					}
				});

				expect(hasIssue(result, "schema.array.itemsMissing")).toBeTrue();
			});

			it("reports invalid component schema values", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Event = "not a schema"
						}
					}
				});

				expect(hasIssue(result, "schema.component.invalid")).toBeTrue();
			});

			it("reports suspicious component schema names", function() {
				var result = linter.lint({
					components = {
						schemas = {
							"Bad Name" = { type = "object" }
						}
					}
				});

				expect(hasIssue(result, "schema.component.nameSuspicious")).toBeTrue();
			});

			it("reports component required properties missing from properties", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Event = {
								type = "object",
								properties = {
									id = { type = "string" }
								},
								required = [ "id", "startDate" ]
							}
						}
					}
				});

				expect(hasIssue(result, "schema.object.requiredPropertyMissing")).toBeTrue();
			});

			it("reports component array schemas without items", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Events = { type = "array" }
						}
					}
				});

				expect(hasIssue(result, "schema.array.itemsMissing")).toBeTrue();
			});

			it("reports component properties with invalid shape", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Event = {
								type = "object",
								properties = {
									id = "bad"
								}
							}
						}
					}
				});

				expect(hasIssue(result, "schema.properties.invalid")).toBeTrue();
			});

			it("reports ambiguous schemas without a type signal", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Ambiguous = {
								properties = {
									id = { type = "string" }
								}
							}
						}
					}
				});

				expect(hasIssue(result, "schema.type.missing")).toBeTrue();
			});

			it("does not require type when schemas use enum or composition", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Choice = { enum = [ "a", "b" ] },
							Composed = {
								oneOf = [
									{ type = "string" },
									{ type = "integer" }
								]
							}
						}
					}
				});

				expect(hasIssue(result, "schema.type.missing")).toBeFalse();
			});

			it("reports unused component schemas as info", function() {
				var result = linter.lint({
					components = {
						schemas = {
							Unused = { type = "object" }
						}
					}
				});

				var issue = issueByCode(result, "schema.component.unused");
				expect(structIsEmpty(issue)).toBeFalse();
				expect(issue.severity).toBe("info");
			});

			it("reports inline object required properties missing from properties", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {
									schema = {
										type = "object",
										properties = {},
										required = [ "id" ]
									}
								}
							}
						}
					}
				}));

				expect(hasIssue(result, "schema.object.requiredPropertyMissing")).toBeTrue();
			});

			it("reports inline array schemas without items", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						"200" = {
							description = "OK",
							content = {
								"application/json" = {
									schema = { type = "array" }
								}
							}
						}
					}
				}));

				expect(hasIssue(result, "schema.array.itemsMissing")).toBeTrue();
			});

			it("reports empty schemas except undocumented default response schemas", function() {
				var result = linter.lint(operationSpec({
					operationId = "listThings",
					responses = {
						default = {
							description = "Response not documented.",
							content = {
								"application/json" = {
									schema = {}
								}
							}
						}
					}
				}));

				expect(hasIssue(result, "schema.empty")).toBeFalse();

				result = linter.lint({
					components = {
						schemas = {
							Empty = {}
						}
					}
				});

				expect(hasIssue(result, "schema.empty")).toBeTrue();
			});

			it("reports unsupported request content types when context includes supported content types", function() {
				var result = linter.lint(
					operationSpec({
						operationId = "createThing",
						requestBody = {
							content = {
								"application/xml" = {
									schema = { type = "object" }
								}
							}
						},
						responses = {
							"201" = { description = "Created" }
						}
					}, "/things", "post"),
					{
						contentTypes = {
							"application/json" = "getFromJson"
						}
					}
				);

				expect(hasIssue(result, "requestBody.contentType.unsupported")).toBeTrue();
			});

			it("reports unsupported response content types when context includes serializer MIME types", function() {
				var result = linter.lint(
					operationSpec({
						operationId = "listThings",
						responses = {
							"200" = {
								description = "OK",
								content = {
									"application/xml" = {
										schema = { type = "object" }
									}
								}
							}
						}
					}),
					{
						settings = {
							mimeTypes = {
								"application/json" = "json"
							}
						}
					}
				);

				expect(hasIssue(result, "response.contentType.unsupported")).toBeTrue();
			});

			it("includes source-map location and target when available", function() {
				var result = linter.lint(
					operationSpec({
						operationId = "listThings",
						responses = {
							"200" = {
								description = "OK",
								content = {
									"application/json" = {}
								}
							}
						}
					}),
					{
						sourceMap = {
							"/paths/~1things/get" = {
								resource = "ThingsResource",
								method = "get",
								docsMethod = "getOpenAPIDocs",
								operation = "GET /things"
							}
						}
					}
				);

				var issue = issueByCode(result, "response.content.schema.missing");

				expect(issue.location.operation).toBe("GET /things");
				expect(issue.location.target).toBe("response 200 application/json");
			});

			it("sorts issues by severity, path, then code", function() {
				var result = linter.lint(operationSpec({
					parameters = [
						{ name = "id", "in" = "path", required = false }
					],
					responses = {
						default = { description = "Response not documented." }
					}
				}, "/things/{id}"));

				expect(result.issues[1].severity).toBe("error");
				expect(result.issues[arrayLen(result.issues)].severity).notToBe("error");
			});

		});

	}

}
