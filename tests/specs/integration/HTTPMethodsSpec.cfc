component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Initialize application scope with minimal settings required by resource.cfc
		application._taffy = {
			settings: {
				serializer: "core.nativeJsonSerializer",
				noDataSends204NoContent: false
			},
			factory: new core.factory(),
			compat: {
				queryToArray: "missing",
				queryToStruct: "missing"
			}
		};
	}

	function run() {

		describe("HTTP Methods", function() {

			describe("Standard HTTP verb mapping", function() {

				it("should recognize GET method in resource", function() {
					var resource = new tests.resources.MockSimpleResource();
					var meta = getMetadata(resource);
					var hasGet = false;
					for (var func in meta.functions) {
						if (func.name == "get") {
							hasGet = true;
							break;
						}
					}
					expect(hasGet).toBeTrue();
				});

				it("should recognize POST method in resource", function() {
					var resource = new tests.resources.MockSimpleResource();
					var meta = getMetadata(resource);
					var hasPost = false;
					for (var func in meta.functions) {
						if (func.name == "post") {
							hasPost = true;
							break;
						}
					}
					expect(hasPost).toBeTrue();
				});

				it("should recognize PUT method in resource", function() {
					var resource = new tests.resources.MockTokenResource();
					var meta = getMetadata(resource);
					var hasPut = false;
					for (var func in meta.functions) {
						if (func.name == "put") {
							hasPut = true;
							break;
						}
					}
					expect(hasPut).toBeTrue();
				});

				it("should recognize DELETE method in resource", function() {
					var resource = new tests.resources.MockTokenResource();
					var meta = getMetadata(resource);
					var hasDelete = false;
					for (var func in meta.functions) {
						if (func.name == "delete") {
							hasDelete = true;
							break;
						}
					}
					expect(hasDelete).toBeTrue();
				});

			});

			describe("taffy:verb metadata override", function() {

				it("should recognize taffy:verb=PATCH on custom method", function() {
					var resource = new tests.resources.MockVerbOverrideResource();
					var meta = getMetadata(resource);
					var patchFunc = "";
					for (var func in meta.functions) {
						if (func.name == "updatePartial") {
							patchFunc = func;
							break;
						}
					}
					expect(patchFunc).notToBeEmpty();
					var hasVerbMeta = structKeyExists(patchFunc, "taffy:verb")
						|| structKeyExists(patchFunc, "taffy_verb");
					expect(hasVerbMeta).toBeTrue();

					var verbValue = structKeyExists(patchFunc, "taffy:verb")
						? patchFunc["taffy:verb"]
						: patchFunc["taffy_verb"];
					expect(verbValue).toBe("PATCH");
				});

				it("should recognize taffy_verb (underscore style) on custom method", function() {
					var resource = new tests.resources.MockVerbOverrideResource();
					var meta = getMetadata(resource);
					var optionsFunc = "";
					for (var func in meta.functions) {
						if (func.name == "handleOptions") {
							optionsFunc = func;
							break;
						}
					}
					expect(optionsFunc).notToBeEmpty();
					var hasVerbMeta = structKeyExists(optionsFunc, "taffy:verb")
						|| structKeyExists(optionsFunc, "taffy_verb");
					expect(hasVerbMeta).toBeTrue();
				});

			});

			describe("Resource taffy:uri metadata", function() {

				it("should have taffy:uri on MockSimpleResource", function() {
					var resource = new tests.resources.MockSimpleResource();
					var meta = getMetadata(resource);
					var hasUri = structKeyExists(meta, "taffy:uri")
						|| structKeyExists(meta, "taffy_uri");
					expect(hasUri).toBeTrue();
				});

				it("should have correct URI pattern on MockTokenResource", function() {
					var resource = new tests.resources.MockTokenResource();
					var meta = getMetadata(resource);
					var uri = structKeyExists(meta, "taffy:uri")
						? meta["taffy:uri"]
						: meta["taffy_uri"];
					expect(uri).toBe("/items/{id}");
				});

				it("should have correct URI pattern on MockMultiTokenResource", function() {
					var resource = new tests.resources.MockMultiTokenResource();
					var meta = getMetadata(resource);
					var uri = structKeyExists(meta, "taffy:uri")
						? meta["taffy:uri"]
						: meta["taffy_uri"];
					expect(uri).toBe("/users/{userId}/orders/{orderId}");
				});

			});

			describe("Resource inheritance", function() {

				it("should extend core.resource", function() {
					var resource = new tests.resources.MockSimpleResource();
					expect(resource).toBeInstanceOf("core.resource");
				});

				it("should have access to rep() method from parent", function() {
					var resource = new tests.resources.MockSimpleResource();
					expect(resource).toHaveKey("rep");
				});

				it("should have access to representationOf() method from parent", function() {
					var resource = new tests.resources.MockSimpleResource();
					expect(resource).toHaveKey("representationOf");
				});

			});

			describe("Resource method invocation", function() {

				it("should execute GET and return serializer", function() {
					var resource = new tests.resources.MockSimpleResource();
					var result = resource.get();
					expect(result).toBeInstanceOf("core.baseSerializer");
					expect(result.getData().method).toBe("GET");
				});

				it("should execute POST with arguments", function() {
					var resource = new tests.resources.MockSimpleResource();
					var result = resource.post(name = "TestItem");
					expect(result).toBeInstanceOf("core.baseSerializer");
					expect(result.getData().name).toBe("TestItem");
					expect(result.getStatus()).toBe(201);
				});

				it("should execute GET with token parameter", function() {
					var resource = new tests.resources.MockTokenResource();
					var result = resource.get(id = "123");
					expect(result.getData().id).toBe("123");
					expect(result.getData().method).toBe("GET");
				});

				it("should execute PUT with token and body parameters", function() {
					var resource = new tests.resources.MockTokenResource();
					var result = resource.put(id = "456", name = "Updated");
					expect(result.getData().id).toBe("456");
					expect(result.getData().name).toBe("Updated");
					expect(result.getData().updated).toBeTrue();
				});

				it("should execute DELETE with token parameter", function() {
					var resource = new tests.resources.MockTokenResource();
					var result = resource.delete(id = "789");
					expect(result.getData().id).toBe("789");
					expect(result.getData().deleted).toBeTrue();
				});

				it("should execute GET with multiple tokens", function() {
					var resource = new tests.resources.MockMultiTokenResource();
					var result = resource.get(userId = "1", orderId = "2");
					expect(result.getData().userId).toBe("1");
					expect(result.getData().orderId).toBe("2");
				});

			});

		});

	}

}
