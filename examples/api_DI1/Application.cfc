<cfcomponent extends="taffy.core.api">
<cfscript>

	this.name = hash(getCurrentTemplatePath());

	variables.framework = {};

	function onApplicationStart(){
		application.beanFactory = createObject("component", "di1.ioc").init( "/taffy/examples/api_DI1/model" );

		variables.framework.beanFactory = application.beanFactory;

		return super.onApplicationStart();
	}

</cfscript>
</cfcomponent>