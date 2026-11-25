component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Factory", function() {

			beforeEach(function() {
				variables.factory = new core.factory();
				variables.parseDir = expandPath("/tests/resources/factoryParse");
			});

			describe("init()", function() {

				it("should initialize with empty bean cache", function() {
					expect(factory.beans).toBeStruct();
					expect(structIsEmpty(factory.beans)).toBeTrue();
				});

				it("should initialize with empty path cache", function() {
					expect(factory.paths).toBeStruct();
					expect(structIsEmpty(factory.paths)).toBeTrue();
				});

				it("should initialize with empty transients cache", function() {
					expect(factory.transients).toBeStruct();
					expect(structIsEmpty(factory.transients)).toBeTrue();
				});

				it("should return this for method chaining", function() {
					var result = factory.init();
					expect(new tests.helpers.MetadataHelper().extendsClass(result, "factory")).toBeTrue();
				});

			});

			describe("beanExists() / containsBean()", function() {

				it("should return false for non-existent bean", function() {
					expect(factory.beanExists("nonExistent")).toBeFalse();
					expect(factory.containsBean("nonExistent")).toBeFalse();
				});

				it("should return true for cached bean", function() {
					factory.beans["testBean"] = { name: "test" };
					expect(factory.beanExists("testBean")).toBeTrue();
					expect(factory.containsBean("testBean")).toBeTrue();
				});

				it("containsBean should be alias for beanExists", function() {
					factory.beans["aliasTest"] = { name: "test" };
					expect(factory.containsBean("aliasTest")).toBe(factory.beanExists("aliasTest"));
				});

			});

			describe("transientExists()", function() {

				it("should return false for non-existent transient", function() {
					expect(factory.transientExists("nonExistent")).toBeFalse();
				});

				it("should return true for cached transient", function() {
					factory.transients["testTransient"] = "some.component.path";
					expect(factory.transientExists("testTransient")).toBeTrue();
				});

			});

			describe("getBean()", function() {

				it("should return cached bean if exists", function() {
					var testObj = { name: "cached bean" };
					factory.beans["testBean"] = testObj;
					var result = factory.getBean("testBean");
					expect(result.name).toBe("cached bean");
				});

				it("should throw error for non-existent bean", function() {
					expect(function() {
						factory.getBean("nonExistent");
					}).toThrow("Taffy.Factory.BeanNotFound");
				});

			});

			describe("getBeanList()", function() {

				it("should return empty string when no beans", function() {
					expect(factory.getBeanList()).toBe("");
				});

				it("should return bean names as comma-separated list", function() {
					factory.beans["bean1"] = {};
					factory.beans["bean2"] = {};
					var list = factory.getBeanList();
					expect(listLen(list)).toBe(2);
					expect(listFindNoCase(list, "bean1")).toBeGT(0);
					expect(listFindNoCase(list, "bean2")).toBeGT(0);
				});

				it("should include transients in the list", function() {
					factory.beans["bean1"] = {};
					factory.transients["transient1"] = "some.path";
					var list = factory.getBeanList();
					expect(listLen(list)).toBe(2);
					expect(listFindNoCase(list, "transient1")).toBeGT(0);
				});

				it("should include paths in the list", function() {
					factory.paths["pathBean1"] = "some.path.PathBean";
					var list = factory.getBeanList();
					expect(listFindNoCase(list, "pathBean1")).toBeGT(0);
				});

			});

			describe("loadBeansFromPath()", function() {

				it("should not throw error for non-existent path", function() {
					// loadBeansFromPath should handle non-existent directories gracefully
					expect(function() {
						factory.loadBeansFromPath("/non/existent/path");
					}).notToThrow();
				});

				it("should clear beans and paths on full reload", function() {
					factory.beans["existingBean"] = {};
					factory.paths["pathBean"] = "some.path";
					factory.filePaths["pathBean"] = "/tmp/path.cfc";
					factory.metaCache["pathBean"] = {};
					factory.resourceNames["pathBean"] = true;
					var taffyRef = {
						status: { skippedResources: [] },
						beanList: ""
					};
					factory.loadBeansFromPath(
						beanPath = "/non/existent/path",
						resourcesPath = "resources",
						resourcesBasePath = "",
						isFullReload = true,
						taffyRef = taffyRef
					);
					// After reload with non-existent path, beans and paths should be cleared
					expect(structIsEmpty(factory.beans)).toBeTrue();
					expect(structIsEmpty(factory.paths)).toBeTrue();
					expect(structIsEmpty(factory.filePaths)).toBeTrue();
					expect(structIsEmpty(factory.metaCache)).toBeTrue();
					expect(structIsEmpty(factory.resourceNames)).toBeTrue();
				});

			});

			describe("pathExists() / beanExists() for paths", function() {

				it("beanExists should find beans that only exist as paths", function() {
					factory.paths["pathBean"] = "tests.resources.MockSimpleResource";
					expect(factory.beanExists("pathBean")).toBeTrue();
					expect(factory.pathExists("pathBean")).toBeTrue();
				});

			});

			describe("deferred load and source metadata parse", function() {

				beforeEach(function() {
					var taffyRef = {
						status: { skippedResources: [] },
						beanList: ""
					};
					factory.loadBeansFromPath(
						beanPath = parseDir,
						resourcesPath = "tests.resources.factoryParse",
						resourcesBasePath = parseDir,
						isFullReload = true,
						taffyRef = taffyRef
					);
					variables.taffyRef = taffyRef;
				});

				it("should not createObject resources at load time", function() {
					expect(structIsEmpty(factory.beans)).toBeTrue();
					expect(factory.pathExists("TagCollection")).toBeTrue();
					expect(factory.pathExists("ScriptMember")).toBeTrue();
					expect(factory.pathExists("HelperNoUri")).toBeTrue();
				});

				it("getResourceBeanList should include only beans with taffy uri", function() {
					var resources = factory.getResourceBeanList();
					expect(listFindNoCase(resources, "TagCollection")).toBeGT(0);
					expect(listFindNoCase(resources, "ScriptMember")).toBeGT(0);
					expect(listFindNoCase(resources, "TagVerbOverride")).toBeGT(0);
					expect(listFindNoCase(resources, "HelperNoUri")).toBe(0);
					expect(listFindNoCase(resources, "TagSerializer")).toBe(0);
				});

				it("should parse tag-syntax HTTP verbs", function() {
					var meta = factory.getBeanMetaData("TagCollection");
					expect(meta["taffy:uri"]).toBe("/factory-parse/artists");
					var names = "";
					for (var f in meta.functions) {
						names = listAppend(names, f.name);
					}
					expect(listFindNoCase(names, "get")).toBeGT(0);
					expect(listFindNoCase(names, "post")).toBeGT(0);
				});

				it("should parse script-syntax HTTP verbs", function() {
					var meta = factory.getBeanMetaData("ScriptMember");
					expect(meta["taffy:uri"]).toBe("/factory-parse/artist/{id}");
					var names = "";
					for (var f in meta.functions) {
						names = listAppend(names, f.name);
					}
					expect(listFindNoCase(names, "get")).toBeGT(0);
					expect(listFindNoCase(names, "put")).toBeGT(0);
					expect(listFindNoCase(names, "delete")).toBeGT(0);
				});

				it("should parse tag taffy:verb / taffy_verb overrides", function() {
					var meta = factory.getBeanMetaData("TagVerbOverride");
					var patchName = "";
					var optionsName = "";
					for (var f in meta.functions) {
						if (structKeyExists(f, "taffy:verb") && uCase(f["taffy:verb"]) == "PATCH") {
							patchName = f.name;
						}
						if (structKeyExists(f, "taffy:verb") && uCase(f["taffy:verb"]) == "OPTIONS") {
							optionsName = f.name;
						}
					}
					expect(patchName).toBe("updatePartial");
					expect(optionsName).toBe("handleOptions");
				});

				it("should classify serializers as transients including getAs+mime without direct baseSerializer extends", function() {
					expect(factory.transientExists("TagSerializer")).toBeTrue();
					expect(factory.transientExists("IndirectSerializer")).toBeTrue();
					expect(factory.transientExists("LocalSerializerBase")).toBeTrue();
					expect(factory.pathExists("TagSerializer")).toBeFalse();
				});

				it("getBeanMetaData should use cached parse without createObject", function() {
					expect(structIsEmpty(factory.beans)).toBeTrue();
					var meta = factory.getBeanMetaData("TagCollection");
					expect(meta["taffy:uri"]).toBe("/factory-parse/artists");
					expect(structIsEmpty(factory.beans)).toBeTrue();
				});

				it("should parse a real examples tag resource for verbs", function() {
					makePublic(factory, "parseCfcMetaData");
					var exampleFile = expandPath("/taffy/examples/api_twoFormats/resources/artistCollection.cfc");
					var meta = factory.parseCfcMetaData(exampleFile);
					expect(meta["taffy:uri"]).toBe("/artists");
					var names = "";
					for (var f in meta.functions) {
						names = listAppend(names, f.name);
					}
					expect(listFindNoCase(names, "get")).toBeGT(0);
					expect(listFindNoCase(names, "post")).toBeGT(0);
				});

			});

			describe("External bean factory integration", function() {

				it("should accept external bean factory in init", function() {
					var mockExternalFactory = {
						containsBean: function(beanName) { return beanName == "externalBean"; },
						getBean: function(beanName) { return { name: "external" }; }
					};
					factory.init(mockExternalFactory);
					expect(structKeyExists(factory, "externalBeanFactory")).toBeTrue();
				});

				it("should check external factory for beans when configured", function() {
					var mockExternalFactory = {
						containsBean: function(beanName) { return beanName == "externalBean"; },
						getBean: function(beanName) { return { name: "from external", source: "external" }; }
					};
					factory.init(mockExternalFactory);

					// beanExists with includeExternal=true should find external beans
					expect(factory.beanExists("externalBean", true, true)).toBeTrue();
				});

			});

		});

	}

}
