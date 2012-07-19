<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";

		variables.framework = {
			disableDashboard = false
			,reloadKey = "reload"
			,unhandledPaths = "/Taffy/tests/someFolder,/Taffy/tests/tests,/tests/someFolder,/tests/tests"
			,defaultRepresentationClass = "customJsonRepresentation"
			,globalHeaders = {
				"x-foo-globalheader" = "snafu"
			}
		};

		function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers) {
			//pass data into a resource by modifying requestArguments
			if (structKeyExists(arguments.requestArguments, "hulk") and arguments.requestArguments.hulk eq "smash"){
				arguments.requestArguments.dataFromOTR = "who let the hulk out?!";
			}

			if (structKeyExists(arguments.requestArguments, "refuse") and arguments.requestArguments.refuse)
			{
				return newRepresentation().withStatus(405);
			}
			else
			{
				return true;
			}
		}
	</cfscript>
</cfcomponent>