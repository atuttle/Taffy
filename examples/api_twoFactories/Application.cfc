<cfcomponent extends="taffy.core.api">
	<cfscript>
		this.name = hash(getCurrentTemplatePath());

		variables.framework = {};
		variables.framework.reloadKey = "reload";

		/*
			You should NOT create your bean factory instance out here because that would cause it to be
			re-created for every request, which is not going to be efficient at all!

			Because of the Taffy Request Lifecycle, onApplicationStart is called BEFORE inspecting
			your framework default settings, so you can optionally set the bean factory into
			variables.framework from inside onApplicationStart.

			Note that this does not stop you from setting values above; as I've set the value for
			reloadKey. You can mix implementations like this; but anything that will have a significant
			load time should be done in onApplicationStart.
		*/

		function onApplicationStart(){
			application.coldspring = createObject("component", "coldspring.beans.DefaultXMLBeanFactory");
			application.coldspring.loadBeans('config/coldspring.xml');

			variables.framework.beanFactory = application.coldspring;

			return super.onApplicationStart();
		}
	</cfscript>
</cfcomponent>
