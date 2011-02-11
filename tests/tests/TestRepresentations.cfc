component extends="baseTest" {

	function beforeTests(){
		variables.representation = createObject("taffy.core.baseRepresentation");
	}

	function test_setData_getData(){
		variables.representation.setData(10);
		assertEquals(10, variables.representation.getData());
	}

	function noData_returns_empty_rep_obj(){
		local.result = variables.representation.noData();
		local.meta = getMetaData(local.result);
		debug(local.meta);
		assertEquals(true, 'taffy.core.baseRepresentation' eq local.meta.fullname and local.result.getData() eq "");
	}

	function test_withStatus_getStatus(){
		variables.representation.withStatus(42);
		assertEquals(42, variables.representation.getStatus());
	}

	function test_withHeaders_getHeaders(){
		local.h = { 'x-dude'='dude!'};
		variables.representation.withHeaders(local.h);
		assertEquals(true, structKeyExists(variables.representation.getHeaders(), "x-dude"));
	}

}
