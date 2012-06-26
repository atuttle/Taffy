<cfcomponent extends="base">
	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			variables.factory = variables.taffy.getBeanFactory();
		}

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

		function skips_resources_with_errors(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'resourcesError' );
			debug(application._taffy.status);
			assertTrue(structKeyExists(application._taffy.status, "skippedResources"));
		}

		function lists_skipped_resources(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'resourcesError' );
			debug(application._taffy.status);
			assertTrue(structKeyExists(application._taffy.status, "skippedResources"));
			assertTrue( arrayLen(application._taffy.status.skippedResources) gt 0 );
		}

		function clears_skipped_resources_on_reload(){
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resourcesError'), 'resourcesError' );
			debug(application._taffy.status);
			assertTrue(structKeyExists(application._taffy.status, "skippedResources"));
			assertTrue( arrayLen(application._taffy.status.skippedResources) gt 0 );

			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources' );
			debug(application._taffy.status);
			assertTrue(structKeyExists(application._taffy.status, "skippedResources"));
			assertTrue( ArrayLen(application._taffy.status.skippedResources) eq 0, "Expected skipped resources array to be empty but it wasn't" );
		}

	</cfscript>
</cfcomponent>