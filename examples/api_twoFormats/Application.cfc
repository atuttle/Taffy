<cfcomponent extends="taffy.core.api">
	<cfscript>
		
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.representationClass = "resources.CustomRepresentationClass";

		function applicationStartEvent(){
			application.JsonUtil = createObject("component", "resources.JSONUtil.JSONUtil");
			application.AnythingToXML = createObject("component", "resources.AnythingToXML.AnythingToXML");
		}

	</cfscript>
</cfcomponent>
