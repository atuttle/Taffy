<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.serializer = "JsonUtilSerializer";

	</cfscript>
</cfcomponent>
