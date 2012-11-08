<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.representationClass = "taffy.core.nativeJsonRepresentation";

		// do your onApplicationStart stuff here
		function applicationStartEvent(){
			application.lastReset = now();
		}

	</cfscript>
</cfcomponent>
