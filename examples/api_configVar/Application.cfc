<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		// In the interest of compatibility, we'll write this out long-form so it works on CF8
		variables.framework = structNew();
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.serializer = "taffy.core.nativeJsonSerializer";
		variables.framework.dashboardKey = "dashboard";
		variables.framework.disableDashboard = false;
		variables.framework.unhandledPaths = "/flex2gateway";
		variables.framework.allowCrossDomain = false;
		variables.framework.globalHeaders = structNew();
		variables.framework.globalHeaders["X-MY-HEADER"] = "my header value";
		//variables.framework.beanFactory = "";


		/* If you have CF9+, the above could be written as:

			variables.framework {
				debugKey = "debug",
				reloadKey = "reload",
				reloadPassword = "true",
				serializer = "taffy.core.nativeJsonSerializer",
				dashboardKey = "dashboard",
				disableDashboard = false,
				unhandledPaths = "/flex2gateway",
				allowCrossDomain = false,
				globalHeaders = {
					"X-MY-HEADER" = "my header value"
				}
			}
		*/

	</cfscript>
</cfcomponent>
