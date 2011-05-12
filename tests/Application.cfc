<cfcomponent extends="taffy.core.api" output="false">
	<cfscript>
		this.name = "Taffy_testSuite";
		
		this.mappings = {};
		this.mappings["/"] = ExpandPath(".");

		function configureTaffy() {
			var local = {};
			local.headers["x-foo-globalheader"] = "snafu";
			
			enableDashboard(true);
			setReloadKey("reload");

			// Don't try to handle the Unit Test Suite files
			setUnhandledPaths('/taffy/tests/someFolder,/taffy/tests/tests');
			
			setGlobalHeaders(local.headers);
			//setDefaultRepresentationClass("customJsonRepresentation");
		}
	
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers) {
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