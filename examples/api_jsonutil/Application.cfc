<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		function configureTaffy(){
			setDefaultRepresentationClass("JsonUtilRepresentation");
		}

	</cfscript>
</cfcomponent>
