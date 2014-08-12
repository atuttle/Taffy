<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		// this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){

			if(not structKeyExists(arguments.requestArguments, "apiKey")){
				//unauthorized because they haven't included their API key
				return noData().withStatus(401);
			}

			//api key found
			return true;
		}

	</cfscript>
</cfcomponent>
