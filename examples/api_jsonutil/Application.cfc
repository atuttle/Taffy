<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.defaultRepresentationClass = "JsonUtilRepresentation";

	</cfscript>
</cfcomponent>
