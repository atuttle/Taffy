<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		//called when taffy is initializing or when a reload is requested
		function configureTaffy(){

			//you do not HAVE TO set this into a persistent scope (application, server), because Taffy does this for you.
			//however, you might want to if you need to reference it in other places as well.
			var beanFactory = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
			beanFactory.loadBeans('config/coldspring.xml');

			//set bean factory into Taffy
			setBeanFactory(beanfactory);
		}
	</cfscript>
</cfcomponent>