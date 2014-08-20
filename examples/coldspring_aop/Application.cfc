<cfcomponent extends="taffy.core.api">
	<cfscript>

		this.name = hash(getCurrentTemplatePath());
		this.applicationTimeout = createTimeSpan(0,0,0,1);
		this.mappings = structNew();
		//this.mappings["/coldspring"] = ExpandPath("{your-path-here}");

		variables.framework = {};
		variables.framework.debugKey = "debug";
		variables.framework.reloadKey = "reload";
		variables.framework.reloadPassword = "true";
		variables.framework.serializer = "taffy.core.nativeJsonSerializer";

		function onApplicationStart(){
			initColdSpring();

			return super.onApplicationStart();
		}

		function initColdSpring() {
			application.oBeanFactory = CreateObject("component","coldspring.beans.DefaultXmlBeanFactory").init();
			application.oBeanFactory.loadBeansFromXMLFile("/config/coldspring.xml");
		}

	</cfscript>
</cfcomponent>
