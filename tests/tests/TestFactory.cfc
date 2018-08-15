<cfcomponent extends="base">
	<cfscript>

		function setup() {
			reloadFramework();
		}


		function beforeTests(){
			request["_testsRunning"] = true;
			variables.taffy = createObject("component","taffy.tests.Application");
			makePublic(variables.taffy, "getBeanFactory");
			variables.factory = variables.taffy.getBeanFactory();
			//debug(variables.factory);
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true, variables.taffy);
		}

		function test_throws_on_getBean_not_exists(){
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

		function test_autowires_properties_in_beans(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'EchoMember' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency1") );
			assertFalse( isSimpleValue(local.bean.dependency1) );
		}

		function test_autowires_setters_in_beans(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'EchoRegexMember' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency2") );
			assertFalse( isSimpleValue(local.bean.dependency2) );
		}

		function test_autowires_properties_in_transients(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'CustomJsonSerializer' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency1") );
			assertFalse( isSimpleValue(local.bean.dependency1) );
		}

		function test_autowires_setters_in_transients(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
			local.bean = variables.factory.getBean( 'CustomJsonSerializer' );
			// debug(local.bean);
			assertTrue( structKeyExists(local.bean, "dependency2") );
			assertFalse( isSimpleValue(local.bean.dependency2) );
		}

		function test_skips_resources_with_errors(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
		}

		function test_lists_skipped_resources(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true, variables.taffy);
			debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( arrayLen(variables.taffy.status.skippedResources) gt 0 );
		}

		function test_clears_skipped_resources_on_reload(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'taffy.tests.resourcesError', expandPath('/taffy/tests/resourcesError'), true, variables.taffy );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( arrayLen(variables.taffy.status.skippedResources) gt 0 );

			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true, variables.taffy );
			// debug(variables.taffy.status);
			assertTrue(structKeyExists(variables.taffy.status, "skippedResources"));
			assertTrue( ArrayLen(variables.taffy.status.skippedResources) eq 0, "Expected skipped resources array to be empty but it wasn't" );
		}

		function test_treats_CRCs_as_transients(){
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

	</cfscript>
</cfcomponent>
