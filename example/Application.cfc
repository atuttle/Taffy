component extends="taffy.core.api" {
	this.name = hash(getCurrentTemplatePath());

	this.mappings = {};
	this.mappings["/taffy"] = expandPath('.');

	//this function is where you can set your own application variables. It is called by onApplicationStart.
	//reminder: DO NOT OVERRIDE onApplicationStart! The framework uses it for its own purposes.
	function applicationHook(){
		setDebugKey("debug");
		setReloadKey("reload");
		setReloadPassword("true");

		defaultMime("json");//not necessary because the framework default is json, but this is how you would change it to something else.
	}

	//this gets called by setupFramework in the framework core, allowing the api implementation to
	//notify the framework what endpoints to implement
	function createEndpoints(){

		//let taffy know about the cfcs in your api so that it can map urls to them
		addEndpoint("taffy.example.api.artCollection");
		addEndpoint("taffy.example.api.artMember");
		addEndpoint("taffy.example.api.artistCollection");
		addEndpoint("taffy.example.api.artistMember");

	}

}
