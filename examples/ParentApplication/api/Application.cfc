component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";
	this.mappings = {};
	this.mappings["/taffy"] = expandPath('.');

	//do your onApplicationStart stuff here
	function applicationStartEvent(){}

	//do your onRequestStart stuff here
	function requestStartEvent(){}

	//this function is called after the request has been parsed and all request details are known
	function onTaffyRequest(string verb, string cfc, struct requestArguments, string mimeExt){
writeDump(application);
abort;
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
