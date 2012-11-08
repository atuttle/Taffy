<cfcomponent extends="taffy.core.api">
	<cfscript>
		
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};

		variables.framework.exceptionLogAdapter = "taffy.bonus.LogToBugLogHQ";

		variables.framework.exceptionLogAdapterConfig = StructNew();
		variables.framework.exceptionLogAdapterConfig.bugLogListener = "bugLog.listeners.bugLogListenerWS";
		variables.framework.exceptionLogAdapterConfig.bugEmailRecipients = "you@yourdomain.com";
		variables.framework.exceptionLogAdapterConfig.bugEmailSender = "errors@yourdomain.com";
		variables.framework.exceptionLogAdapterConfig.hostname = "Taffy_DEV_Examples";
		variables.framework.exceptionLogAdapterConfig.apikey = "";

	</cfscript>
</cfcomponent>
