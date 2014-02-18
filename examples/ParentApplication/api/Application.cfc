component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";//same name as api folder application.cfc

	variables.framework = {};
	variables.framework.beanFactory = "";

	function onApplicationStart(){
		include "../mixin/appInit.cfm";

		variables.framework.beanFactory = application.beanFactory;

		return super.onApplicationStart();
	}

}
