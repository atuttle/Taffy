<cfcomponent extends="base">
	<cfscript>

		function beforeTests(){

		}


		function loads_directory_named_resources() {
			// Setup external factory to read resource directory.  Ignore resources that were designed to cause errors.
			local.config = {
				exclude = ["uriDoesnt","uriAliasDoesnt","conflict"]
			};

			variables.beanFactory = createObject("component", "di1.ioc").init(["/taffy/tests/resources"], local.config);


			// Setup Taffy with new bean factory to use and call 'onApplicationStart' to properly initialize.
			variables.taffy = createObject("component","taffy.tests.Application");

			makePublic(variables.taffy, "getExternalBeanFactory");
			makePublic(variables.taffy, "getBeanListFromExternalFactory");

			injectMethod(variables.taffy, this, "_getVariables", "getVariables");

			local.vars = variables.taffy.getVariables();
			local.vars.framework.beanFactory = variables.beanFactory;

			variables.taffy.onApplicationStart();


			// Grab the resource list and compare.
			local.resourceList = variables.taffy.getBeanListFromExternalFactory(variables.taffy.getExternalBeanFactory());

			debug("Available resources from external factory: '" & replace(local.resourceList, ",", ", ", "all") & "'");
			assert(listLen(local.resourceList) gt 0, "No resources were loaded from the external factory.");
		}


		function loads_explicit_named_resources() {
			// Setup external factory to read resource directory.  Ignore resources that were designed to cause errors.
			local.config = {
				exclude = ["uriDoesnt","uriAliasDoesnt","conflict"],
				omitDirectoryAliases = true
			};

			variables.beanFactory = createObject("component", "di1.ioc").init(["/taffy/tests/resources"], local.config);


			// Setup Taffy with new bean factory to use and call 'onApplicationStart' to properly initialize.
			variables.taffy = createObject("component","taffy.tests.Application");

			makePublic(variables.taffy, "getExternalBeanFactory");
			makePublic(variables.taffy, "getBeanListFromExternalFactory");

			injectMethod(variables.taffy, this, "_getVariables", "getVariables");

			local.vars = variables.taffy.getVariables();
			local.vars.framework.beanFactory = variables.beanFactory;

			variables.taffy.onApplicationStart();


			// Grab the resource list and compare.
			local.resourceList = variables.taffy.getBeanListFromExternalFactory(variables.taffy.getExternalBeanFactory());

			debug("Available resources from external factory: '" & replace(local.resourceList, ",", ", ", "all") & "'");
			assert(listLen(local.resourceList) gt 0, "No resources were loaded from the external factory.");
		}


		private function _getVariables(){
			return variables;
		}


	</cfscript>
</cfcomponent>
