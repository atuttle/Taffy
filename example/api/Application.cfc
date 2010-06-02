component extends="taffy.core.api" {

	this.name = hash(getCurrentTemplatePath());
	this.mappings = {};
	this.mappings["/taffy"] = expandPath('.');

	//this function is where you can set your own application variables. It is called by onApplicationStart.
	//reminder: DO NOT OVERRIDE onApplicationStart! The framework uses it for its own purposes.
	void function applicationHook(){

		setDebugKey("debug");
		setReloadKey("reload");
		setReloadPassword("true");

		//TODO: allow setDefaultRepresentationClass("path.to.representationcfc")

		registerMimeType("json", "text/json");

	}

	//this gets called by setupFramework in the framework core, allowing the api implementation
	//to notify the framework what URIs to implement
	void function registerURIs(){

		//let taffy know about the cfcs in your api so that it can map URIs to them
		addURI("taffy.example.api.artCollection");
		addURI("taffy.example.api.artMember");
		addURI("taffy.example.api.artistCollection");
		addURI("taffy.example.api.artistMember");

	}

}
