<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());
		this.applicationTimeout = createTimeSpan(0,0,0,1);
		this.mappings = structNew();
		//this.mappings["/coldspring"] = ExpandPath("{your-path-here}");
		
		// do your onApplicationStart stuff here
		function applicationStartEvent(){
			initColdSpring();
		}

		// do your onRequestStart stuff here
		function requestStartEvent(){}

		// this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){
			// this would be a good place for you to check API key validity and other non-resource-specific validation
			return true;
		}

		// called when taffy is initializing or when a reload is requested
		function configureTaffy(){
			setDebugKey("debug");
			setReloadKey("reload");
			setReloadPassword("true");
			setBeanFactory(application.oBeanFactory);
			// Usage of this function is entirely optional. You may omit it if you want to use the default representation class.
			// Change this to a custom class to change the default for the entire API instead of overriding for every individual response.
			setDefaultRepresentationClass("taffy.core.genericRepresentation");
		}


		function initColdSpring() {
			application.oBeanFactory = CreateObject("component","coldspring.beans.DefaultXmlBeanFactory").init();
			application.oBeanFactory.loadBeansFromXMLFile("/config/coldspring.xml");
		}
		
	</cfscript>
</cfcomponent>
