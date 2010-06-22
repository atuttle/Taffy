component {

	//this application is entirely separate from the api;
	//essentially, it might as well be running on another server.
	this.name = hash(getCurrentTemplatePath());

	function onApplicationStart(){
		application.wsLoc = "http://localhost/taffy/examples/api/index.cfm";
	}

	function onRequestStart(){
		if (structKeyExists(url, "reload") && url.reload == true){
			onApplicationStart();
		}
	}

}
