<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.serializer = "taffy.core.nativeJsonSerializer";

		function onApplicationStart(){
			application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
			application.beanFactory.loadBeans('/taffy/examples/api_coldspring/config/coldspring.xml');

			//note that we're modifying variables.framework here, after the application variable has been set
			variables.framework.beanFactory = application.beanFactory;

			return super.onApplicationStart();
		}

	</cfscript>
</cfcomponent>
