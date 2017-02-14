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






/*
		function throws_on_getBean_not_exists(){
			var local = {};
			local.nonExistentBean = "does_not_exist";

			try{
				local.result = variables.factory.getBean(local.nonExistentBean);
				fail("Expected 'Bean Not Found' exception to be thrown, but none was.");
			} catch (Taffy.Factory.BeanNotFound e) {
				//debug(e);
				assertTrue(findNoCase('not found', e.message) gt 0, "TaffyFactory exception message did not contain the words 'not found'.");
			}
		}

		function autowires_properties_in_beans(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'EchoMember' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency1") );
			assertFalse( isSimpleValue(local.bean.dependency1) );
		}

		function autowires_setters_in_beans(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'EchoRegexMember' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency2") );
			assertFalse( isSimpleValue(local.bean.dependency2) );
		}

		function autowires_properties_in_transients(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'CustomJsonSerializer' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency1") );
			assertFalse( isSimpleValue(local.bean.dependency1) );
		}

		function autowires_setters_in_transients(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'CustomJsonSerializer' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency2") );
			assertFalse( isSimpleValue(local.bean.dependency2) );
		}

		function skips_resources_with_errors(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
		}

		function lists_skipped_resources(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true, variables.taffy);
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( arrayLen(variables.taffy.status.skippedResources) gt 0 );
		}

		function clears_skipped_resources_on_reload(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true, variables.taffy );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( arrayLen(variables.taffy.status.skippedResources) gt 0 );

			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true, variables.taffy );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( ArrayLen(variables.taffy.status.skippedResources) eq 0, "Expected skipped resources array to be empty but it wasn't" );
		}

		function treats_CRCs_as_transients(){
			var local = {};
			//this resource+method explicitly sets response status of 999
			local.result = apiCall("get", "/echo/2.json", "foo=bar");
			// debug(local.result);
			assertEquals(999, local.result.responseHeader.status_code);
			//this resource+method usees the default response status => 200=passing test, 999=failing test
			local.result = apiCall("get", "/echo/tunnel/2.json", "foo=bar");
			// debug(local.result);
			assertEquals(200, local.result.responseHeader.status_code);
		}
*/
	</cfscript>
</cfcomponent>
