component extends="taffy.core.api"{
	this.name = "Taffy_testSuite";

	public void function configureTaffy() output="false" {
		enableDashboard(true);
		setUnhandledPaths('/taffy/tests/someFolder');
		setGlobalHeaders({"x-foo-globalheader"="snafu"});
		setDefaultRepresentationClass("customJsonRepresentation");
	}

	public function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers){
		if (structKeyExists(arguments.requestArguments, "refuse") and arguments.requestArguments.refuse){
			return newRepresentation().withStatus(405);
		}
		return true;
	}
}