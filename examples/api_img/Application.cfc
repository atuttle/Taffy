<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.representationClass = "taffy.core.nativeJsonRepresentation";

		function onApplicationStart(){
			application.lastReset = now();

			return super.onApplicationStart();
		}

	</cfscript>
</cfcomponent>
