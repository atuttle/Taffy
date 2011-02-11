<cfcomponent extends="baseTest">
	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			variables.factory = variables.taffy.getBeanFactory();
		}

		function throws_on_getBean_not_exists(){
			try{
				var result = variables.factory.getBean("does_not_exist");
				debug(result);
			}catch (any e) {
				debug(e);
				assertEquals(true,true);
			}
			assertEquals(true, false);
		}

	</cfscript>
</cfcomponent>