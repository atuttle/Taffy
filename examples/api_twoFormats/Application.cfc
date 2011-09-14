<cfcomponent extends="taffy.core.api">

	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		function applicationStartEvent(){
			application.JsonUtil = createObject("component", "resources.JSONUtil.JSONUtil");
			application.AnythingToXML = createObject("component", "resources.AnythingToXML.AnythingToXML");
		}

		function configureTaffy(){
			setDefaultRepresentationClass("resources.CustomRepresentationClass");
		}
	</cfscript>

</cfcomponent>
