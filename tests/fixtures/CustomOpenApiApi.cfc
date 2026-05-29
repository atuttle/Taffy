component extends="taffy.core.api" {

	variables.framework = {
		resourcesCFCPath: "tests.fixtures.no_such_resources",
		disableDashboard: true,
		openapi: {
			enabled: true,
			description: "Fixture API",
			contact: { name: "API Team", email: "api@example.com" },
			license: { name: "MIT", url: "https://opensource.org/licenses/MIT" },
			servers: [
				{ url: "https://api.example.com", description: "Production" }
			],
			provider: "tests.fixtures.OpenApiInitProvider"
		}
	};

}
