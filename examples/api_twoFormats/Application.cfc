<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.representationClass = "resources.CustomRepresentationClass";

		function onApplicationStart(){
			application.JsonUtil = createObject("component", "resources.JSONUtil.JSONUtil");
			application.AnythingToXML = createObject("component", "resources.AnythingToXML.AnythingToXML");

			return super.onApplicationStart();
		}

	</cfscript>
</cfcomponent>
