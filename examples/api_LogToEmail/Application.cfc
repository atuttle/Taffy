<cfcomponent extends="taffy.core.api">
	<cfscript>
		
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};

		variables.framework.exceptionLogAdapter = "taffy.bonus.LogToEmail";

		variables.framework.exceptionLogAdapterConfig = StructNew();
		variables.framework.exceptionLogAdapterConfig.emailFrom = "api-error@yourdomain.com";
		variables.framework.exceptionLogAdapterConfig.emailTo = "you@yourdomain.com";
		variables.framework.exceptionLogAdapterConfig.emailSubj = "Exception Trapped in API";
		variables.framework.exceptionLogAdapterConfig.emailType = "html";

	</cfscript>
</cfcomponent>
