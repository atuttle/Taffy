component extends="taffy.core.api" {
	this.name = hash(getCurrentTemplatePath());

	this.mappings = {};
	this.mappings["/taffy"] = expandPath('.');

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
