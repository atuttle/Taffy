component {

	//this application is entirely separate from the api;
	//essentially, it might as well be running on another server.
	this.name = hash(getCurrentTemplatePath());

}
