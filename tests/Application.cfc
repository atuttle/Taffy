<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";
		this.dirPath = getDirectoryFromPath(getCurrentTemplatePath());
		this.mappings["/resources"] = this.dirPath & "resources/";
		this.mappings["/mxunit"] = this.dirPath & "testbox/system/compat/";
		this.mappings["/testbox"] = this.dirPath & "testbox/";
		this.mappings["/bugLog"] = this.dirPath & "BugLogHQ/";
		this.mappings["/Hoth"] = this.dirPath & "Hoth/";
		this.mappings["/di1"] = this.dirPath & "di1/";

		this.system = createObject("java", "java.lang.System");
		this.datasources["bugLog"] = {
		  		class: (structKeyExists(server, "lucee")) ? 'org.gjt.mm.mysql.Driver' : 'com.mysql.jdbc.Driver',
		  		connectionString: 'jdbc:mysql://localhost:3306/buglog?useUnicode=true&characterEncoding=UTF-8&serverTimezone=GMT&useLegacyDatetimeCode=false',
		  		url: 'jdbc:mysql://localhost:3306/buglog?useUnicode=true&characterEncoding=UTF-8&serverTimezone=GMT&useLegacyDatetimeCode=false',
		  		username: this.system.getenv("DB_USER"),
		  		password: this.system.getenv("DB_PASS"),
		  		driver: "other"
		};


		variables.framework = {};
		variables.framework.disableDashboard = false;
		variables.framework.reloadKey = "reload";
		variables.framework.unhandledPaths = "/Taffy/tests/someFolder,/Taffy/tests/tests,/tests/someFolder,/tests/tests,BugLogHQ";
		variables.framework.serializer = "nativeJsonSerializer";
		variables.framework.useEtags = true;
		variables.framework.globalHeaders = {};
		variables.framework.globalHeaders["x-foo-globalheader"] = "snafu";
		variables.framework.exposeHeaders = true;

		variables.framework.environments = {};
		variables.framework.environments.test = {};
		variables.framework.environments.test.reloadPassword = 'dontpanic';

		function getCacheKey(cfc, requestArguments, matchedURI) {
			if(structKeyExists(requestArguments, "default")) {
				return super.getCacheKey(argumentCollection = arguments);
			}

			return lCase(arguments.cfc & "_" & listSort(structKeyList(arguments.requestArguments), "textnocase"));
		}

		function getEnvironment(){
			return "test";
		}

		function onRequest(string target) {
			if (arguments.target contains "/BugLogHQ/") {
				return true;
			} else {
				super.onRequest(arguments.target);
			}
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
