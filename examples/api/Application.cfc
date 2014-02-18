<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.representationClass = "taffy.core.genericRepresentation";
		variables.framework.returnExceptionsAsJson = true;

		function onApplicationStart(){
			return super.onApplicationStart();
		}

		function onRequestStart(){
			return super.onRequestStart();
		}

		// this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){
			// this would be a good place for you to check API key validity and other non-resource-specific validation
			return true;
		}

	</cfscript>
</cfcomponent>
