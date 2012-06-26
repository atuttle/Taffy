component extends="taffy.core.api" {

	this.name = "taffy_ParentAppExample";//same name as api folder application.cfc

	//do your onApplicationStart stuff here
	function applicationStartEvent(){
		include "../mixin/appInit.cfm";
	}

	//called when taffy is initializing or when a reload is requested
	void function configureTaffy(){

		//application.beanFactory is defined in the mixin
		setBeanFactory(application.beanFactory);

	}

}
