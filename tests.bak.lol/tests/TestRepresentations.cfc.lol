<cfcomponent extends="base">
	<cfscript>
	function setup(){
		variables.serializer = createObject("component", "taffy.core.baseSerializer");
	}

	function test_setData_getData(){
		variables.serializer.setData(10);
		assertEquals(10, variables.serializer.getData());
	}

	function test_noData_returns_empty_rep_obj(){
		local.result = variables.serializer.noData();
		local.meta = getMetaData(local.result);
		// debug(local.meta);
		// debug(local.result.getData());
		assertEquals('taffy.core.baseSerializer', local.meta.fullname);
		assertEquals("", local.result.getData());
	}

	function test_withStatus_getStatus(){
		variables.serializer.withStatus(42);
		assertEquals(42, variables.serializer.getStatus());
	}

	function test_withStatus_getStatusText(){
		variables.serializer.withStatus(404, "Not Found");
		assertEquals("Not Found", variables.serializer.getStatusText());
		variables.serializer.withStatus(418);
		assertEquals("I'm a teapot", variables.serializer.getStatusText());
	}

	function test_withHeaders_getHeaders(){
		local.h = {};
		local.h['x-dude'] = 'dude!';
		variables.serializer.withHeaders(local.h);
		assertEquals(true, structKeyExists(variables.serializer.getHeaders(), "x-dude"));
	}
	</cfscript>
</cfcomponent>
