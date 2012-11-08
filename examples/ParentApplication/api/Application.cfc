component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";//same name as api folder application.cfc

	variables.framework = {};
	variables.framework.beanFactory = "";

	//do your onApplicationStart stuff here
	function applicationStartEvent(){
		include "../mixin/appInit.cfm";

		variables.framework.beanFactory = application.beanFactory;
	}

}
