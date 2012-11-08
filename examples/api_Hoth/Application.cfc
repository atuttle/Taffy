<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.exceptionLogAdapter = "taffy.bonus.LogToHoth";
		variables.framework.exceptionLogAdapterConfig = "taffy.examples.api_hoth.resources.HothConfig";

	</cfscript>
</cfcomponent>
