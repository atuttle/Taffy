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
				debug("Expected exception to be thrown, but none was.");
			}catch (any e) {
				if (findNoCase('not found', e.detail) gt 0){
					debug(e);
					assertEquals(true,true);
					return;
				}else{
					debug("exception was thrown but not the one we were expecting!");
					debug(e);
					assertEquals(true,false);
					return;
				}
			}
			assertEquals('exception', false);
		}

	</cfscript>
</cfcomponent>