<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";

		function configureTaffy() {
			var local = {};
			local.headers["x-foo-globalheader"] = "snafu";

			enableDashboard(true);
			setReloadKey("reload");

			// Don't try to handle the Unit Test Suite files
			setUnhandledPaths('/Taffy/tests/someFolder,/Taffy/tests/tests,/tests/someFolder,/tests/tests');

			setGlobalHeaders(local.headers);
			setDefaultRepresentationClass("customJsonRepresentation");
		}

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