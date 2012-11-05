<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.unhandledPaths = "/Taffy/examples/api_uploadImg/client";

	</cfscript>
</cfcomponent>