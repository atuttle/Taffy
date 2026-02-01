component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Factory", function() {

			beforeEach(function() {
				variables.factory = new taffy.core.factory();
			});

			describe("init()", function() {

				it("should initialize with empty bean cache", function() {
					expect(factory.beans).toBeStruct();
					expect(structIsEmpty(factory.beans)).toBeTrue();
				});

				it("should initialize with empty transients cache", function() {
					expect(factory.transients).toBeStruct();
					expect(structIsEmpty(factory.transients)).toBeTrue();
				});

				it("should return this for method chaining", function() {
					var result = factory.init();
					expect(result).toBeInstanceOf("taffy.core.factory");
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

			});

			describe("loadBeansFromPath()", function() {

				it("should not throw error for non-existent path", function() {
					// loadBeansFromPath should handle non-existent directories gracefully
					expect(function() {
						factory.loadBeansFromPath("/non/existent/path");
					}).notToThrow();
				});

				it("should clear beans on full reload", function() {
					factory.beans["existingBean"] = {};
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
					// After reload with non-existent path, beans should be cleared
					expect(structIsEmpty(factory.beans)).toBeTrue();
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
