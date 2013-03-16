<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";

		variables.framework = {};
		variables.framework.disableDashboard = false;
		variables.framework.reloadKey = "reload";
		variables.framework.unhandledPaths = "/Taffy/tests/someFolder,/Taffy/tests/tests,/tests/someFolder,/tests/tests";
		variables.framework.representationClass = "customJsonRepresentation";
		variables.framework.useEtags = true;
		variables.framework.globalHeaders = {};
		variables.framework.globalHeaders["x-foo-globalheader"] = "snafu";

		variables.framework.environments = {};
		variables.framework.environments.test = {};
		variables.framework.environments.test.reloadPassword = 'dontpanic';

		function getEnvironment(){
			return "test";
		}

		function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers) {
			var local = {};

			//pass data into a resource by modifying requestArguments
			if (structKeyExists(arguments.requestArguments, "hulk") and arguments.requestArguments.hulk eq "smash"){
				arguments.requestArguments.dataFromOTR = "who let the hulk out?!";
			}

			//get basic auth data, if any, and pass it into the resources
			local.credentials = getBasicAuthCredentials();
			arguments.requestArguments.username = local.credentials.username;
			arguments.requestArguments.password = local.credentials.password;

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