<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.representationClass = "JsonUtilRepresentation";

	</cfscript>
</cfcomponent>
