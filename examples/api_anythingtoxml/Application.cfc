<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.representationClass = "taffy.bonus.AnythingToXmlRepresentation";

		function onApplicationStart(){
			application.anythingToXml = createObject("component", "anythingtoxml.AnythingToXML").init();

			return super.onApplicationStart();
		}

	</cfscript>
</cfcomponent>
