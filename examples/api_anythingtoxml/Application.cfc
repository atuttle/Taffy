<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		function applicationStartEvent(){
			application.anythingToXml = createObject("component", "anythingtoxml.AnythingToXML").init();
		}

		function configureTaffy(){
			setDefaultRepresentationClass("taffy.bonus.AnythingToXmlRepresentation");
		}

	</cfscript>
</cfcomponent>
