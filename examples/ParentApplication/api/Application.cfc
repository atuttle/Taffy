component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";

	//do your onApplicationStart stuff here
	function applicationStartEvent(){
		application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
		application.beanFactory.loadBeans('/taffy/examples/ParentApplication/config/coldspring.xml');

		param name="application.init" default="#structNew()#";
		application.init.api = true;
	}

	//do your onRequestStart stuff here
	function requestStartEvent(){
		if (!structKeyExists(application, "init") || !structKeyExists(application.init, "api")){
			onApplicationStart();
		}
	}

	//this function is called after the request has been parsed and all request details are known
	function onTaffyRequest(string verb, string cfc, struct requestArguments, string mimeExt){
		//this would be a good place for you to check API key validity and other non-resource-specific validation
		return true;
	}

	//called when taffy is initializing or when a reload is requested
	void function configureTaffy(){

		setBeanFactory(application.beanfactory);
		setDebugKey("debug");
		setReloadKey("reload");
		setReloadPassword("true");

		//you could change this to a custom class to change the default instead of specifying an override for each response
		setDefaultRepresentationClass("taffy.core.genericRepresentation");

		//tell Taffy about the parent application's bean factory, which we have access to because
		//we're using the same application name
		setBeanFactory(application.beanFactory);

		//these are both the default settings, but the functions are used here to illustrate how and where you should use them
		registerMimeType("json", "application/json");
		setDefaultMime("json");
	}

}
