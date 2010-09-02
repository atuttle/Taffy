<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		//do your onApplicationStart stuff here
		function applicationStartEvent(){
			application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
			application.beanFactory.loadBeans('config/coldspring.xml');
		}

		//do your onRequestStart stuff here
		function requestStartEvent(){}

		//this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(string verb, string cfc, struct requestArguments, string mimeExt){
			//this would be a good place for you to check API key validity and other non-resource-specific validation
			return true;
		}

		//called when taffy is initializing or when a reload is requested
		function configureTaffy(){
			setBeanFactory(application.beanfactory);
			setDebugKey("debug");
			setReloadKey("reload");
			setReloadPassword("true");

			//you could change this to a custom class to change the default instead of specifying an override for each response
			setDefaultRepresentationClass("taffy.core.genericRepresentation");
		}
	</cfscript>
</cfcomponent>