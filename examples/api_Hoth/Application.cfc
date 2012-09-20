<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {
			returnExceptionsAsJson = true
			,defaultExceptionLogAdapter = "taffy.bonus.LogToHoth"
			,exceptionLogAdapterConfig = "taffy.examples.api_hoth.resources.HothConfig"
		};

	</cfscript>
</cfcomponent>
