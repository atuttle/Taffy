component extends="taffy.core.api" {

	// Point at a non-existent dotted path so directoryExists() returns false in
	// onApplicationStart(). With no external bean factory either, this exercises
	// the "noResources" branch where loadBeansFromPath is never called -- the
	// branch that depends on api.cfc initializing _taffy.status.skippedResources
	// up front rather than relying on factory.cfc to do it.
	variables.framework = {
		resourcesCFCPath: "tests.fixtures.no_such_resources",
		disableDashboard: true
	};

}
