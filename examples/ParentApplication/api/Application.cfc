component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";

	//do your onApplicationStart stuff here
	function applicationStartEvent(){
		application.beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
		application.beanFactory.loadBeans('/taffy/examples/ParentApplication/config/coldspring.xml');

		param name="application.init" default="#structNew()#";
		application.init.api = true;
	}

	//do your onRequestStart stuff here
	function requestStartEvent(){
		if (!structKeyExists(application, "init") || !structKeyExists(application.init, "api")){
			onApplicationStart();
		}
	}

	//called when taffy is initializing or when a reload is requested
	void function configureTaffy(){

		//tell Taffy about the parent application's bean factory, which we have access to because
		//we're using the same application name
		setBeanFactory(application.beanFactory);

	}

}
