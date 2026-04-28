component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		if (structKeyExists(application, "_taffy")) {
			variables.savedTaffy = duplicate(application._taffy);
		}
	}

	function afterAll() {
		if (structKeyExists(variables, "savedTaffy")) {
			application._taffy = variables.savedTaffy;
		}
	}

	function run() {

		describe("API status initialization", function() {

			// cacheBeanMetaData (api.cfc) appends malformed resources to
			// _taffy.status.skippedResources on the external-only-factory path,
			// where loadBeansFromPath (which initializes the array in factory.cfc)
			// never runs. The same code path runs when no resources are found at
			// all. Without the up-front init in api.cfc:608, the array would be
			// missing on these branches.
			it("should initialize status.skippedResources as an empty array even when no resources are loaded", function() {
				var api = new tests.fixtures.NoResourcesApi();
				api.onApplicationStart();

				expect(application._taffy).toHaveKey("status");
				expect(application._taffy.status).toHaveKey("skippedResources");
				expect(application._taffy.status.skippedResources).toBeArray();
				expect(arrayLen(application._taffy.status.skippedResources)).toBe(0);
				expect(application._taffy.status.internalBeanFactoryUsed).toBeFalse();
				expect(application._taffy.status.externalBeanFactoryUsed).toBeFalse();
			});

		});

	}

}
