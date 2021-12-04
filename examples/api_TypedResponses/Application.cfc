<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		this.mappings['/resources'] = expandPath('./resources');

		function onApplicationStart(){
			addTypesPath('/taffy/examples/api_TypedResponses/types');
			return super.onApplicationStart();
		}

	</cfscript>
</cfcomponent>
