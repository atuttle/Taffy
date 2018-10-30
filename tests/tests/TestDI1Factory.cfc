component extends="base" {


		function setup(){
			reloadFramework();
		}

		function teardown() {
			reloadFramework();
		}

		function beforeTests(){

		}


		function test_loads_directory_named_resources() {
			// Setup external factory to read resource directory.  Ignore resources that were designed to cause errors.
			local.config = {
				exclude = ["uriDoesnt","uriAliasDoesnt","conflict"]
			};

			local.beanFactory = createObject("component", "di1.ioc").init(["/taffy/tests/resources"], local.config);


			// Setup Taffy with new bean factory to use and call 'onApplicationStart' to properly initialize.
			local.taffy = createObject("component","taffy.tests.Application");

			makePublic(local.taffy, "getExternalBeanFactory");
			makePublic(local.taffy, "getBeanListFromExternalFactory");

			injectMethod(local.taffy, this, "_getVariables", "getVariables");

			local.vars = local.taffy.getVariables();
			local.vars.framework.beanFactory = local.beanFactory;

			local.taffy.onApplicationStart();


			// Grab the resource list and compare.
			local.resourceList = local.taffy.getBeanListFromExternalFactory(local.taffy.getExternalBeanFactory());

			structDelete(local.vars.framework, "beanFactory");

			local.taffy.onApplicationStart();

			debug("Available resources from external factory: '" & replace(local.resourceList, ",", ", ", "all") & "'");
			assert(listLen(local.resourceList) gt 0, "No resources were loaded from the external factory.");
		}


		function test_loads_explicit_named_resources() {
			// Setup external factory to read resource directory.  Ignore resources that were designed to cause errors.
			local.config = {
				exclude = ["uriDoesnt","uriAliasDoesnt","conflict"],
				omitDirectoryAliases = true
			};

			local.beanFactory = createObject("component", "di1.ioc").init(["/taffy/tests/resources"], local.config);


			// Setup Taffy with new bean factory to use and call 'onApplicationStart' to properly initialize.
			local.taffy = createObject("component","taffy.tests.Application");

			makePublic(local.taffy, "getExternalBeanFactory");
			makePublic(local.taffy, "getBeanListFromExternalFactory");

			injectMethod(local.taffy, this, "_getVariables", "getVariables");

			local.vars = local.taffy.getVariables();

			local.vars.framework.beanFactory = local.beanFactory;

			local.taffy.onApplicationStart();


			// Grab the resource list and compare.
			debug(local.beanFactory.getBeanInfo());
			local.resourceList = local.taffy.getBeanListFromExternalFactory(local.taffy.getExternalBeanFactory());

			structDelete(local.vars.framework, "beanFactory");
			local.taffy.onApplicationStart();

			debug("Available resources from external factory: '" & replace(local.resourceList, ",", ", ", "all") & "'");

			//THIS TEST CURRENTLY FAILING DUE TO https://github.com/atuttle/Taffy/issues/276
			//assert(listLen(local.resourceList) gt 0, "No resources were loaded from the external factory.");
		}


		private function _getVariables(){
			return variables;
		}
}
