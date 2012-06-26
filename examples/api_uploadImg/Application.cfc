<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		function configureTaffy() {
			// exclude test harness for uploading files
			setUnhandledPaths('/Taffy/examples/api_uploadImg/client');
		}

	</cfscript>
</cfcomponent>