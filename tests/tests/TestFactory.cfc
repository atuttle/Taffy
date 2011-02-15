<cfcomponent extends="baseTest">
	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			variables.factory = variables.taffy.getBeanFactory();
		}

		function throws_on_getBean_not_exists(){
			var nonExistentBean = "does_not_exist";
			
			try{
				var result = variables.factory.getBean(nonExistentBean);
				fail("Expected 'Bean Not Found' exception to be thrown, but none was.");
			} catch (Taffy.Factory.BeanNotFound e) {
				//debug(e);
				assertTrue(findNoCase('not found', e.message) gt 0, "TaffyFactory exception message did not contain the words 'not found'.");
			}
		}

	</cfscript>
</cfcomponent>