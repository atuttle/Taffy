component extends="taffy.core.api" {

	this.name = hash(getCurrentTemplatePath());
	this.mappings = {};
	this.mappings["/taffy"] = expandPath('.');

	//do your onApplicationStart stuff here
	function applicationStartEvent(){}
	
	//do your onRequestStart stuff here
	function requestStartEvent(){}

	//called when taffy is initializing or when a reload is requested
	void function configureTaffy(){

		setDebugKey("debug");
		setReloadKey("reload");
		setReloadPassword("true");

		//you could change this to a custom class to change the default instead of specifying an override for each response
		setDefaultRepresentationClass("taffy.core.genericRepresentation");

		registerMimeType("json", "application/json");

		//let taffy know about the cfcs in your api so that it can map URIs to them
		addURI("taffy.example.api.artCollection");
		addURI("taffy.example.api.artMember");
		addURI("taffy.example.api.artistCollection");
		addURI("taffy.example.api.artistMember");
	}

}
