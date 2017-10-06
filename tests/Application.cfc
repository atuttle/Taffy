<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";
		this.dirPath = getDirectoryFromPath(getCurrentTemplatePath());
		this.mappings["/resources"] = this.dirPath & "resources/";
		this.mappings["/mxunit"] = this.dirPath & "testbox/system/compat/";
		this.mappings["/testbox"] = this.dirPath & "testbox/";
		

		variables.framework = {};
		variables.framework.disableDashboard = false;
		variables.framework.reloadKey = "reload";
		variables.framework.unhandledPaths = "/Taffy/tests/someFolder,/Taffy/tests/tests,/tests/someFolder,/tests/tests";
		variables.framework.serializer = "nativeJsonSerializer";
		variables.framework.useEtags = true;
		variables.framework.globalHeaders = {};
		variables.framework.globalHeaders["x-foo-globalheader"] = "snafu";

		variables.framework.environments = {};
		variables.framework.environments.test = {};
		variables.framework.environments.test.reloadPassword = 'dontpanic';

		function getEnvironment(){
			return "test";
		}

		
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers, methodMetadata, matchedURI) {
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
				return noData().withStatus(405);
			}
			else
			{
				return true;
			}
		}
	</cfscript>
</cfcomponent>
