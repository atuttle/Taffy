<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		function applicationStartEvent(){
			application.jsonUtil = createObject("component", "JSONUtil.JSONUtil").init();
		}

		function configureTaffy(){
			setDefaultRepresentationClass("taffy.bonus.JsonUtilRepresentation");
		}

	</cfscript>
</cfcomponent>
