component extends="mxunit.framework.TestCase" {

	function beforeTests(){
		variables.representation = createObject("taffy.core.baseRepresentation");
	}

	function setData_sets_data(){
		variables.representation.setData(10);
		assertEquals(10, variables.representation.getData());
	}

	function noData_returns_emptyObj(){
		local.result = variables.representation.noData();
		local.meta = getMetaData(local.result);
		debug(local.meta);
		assertEquals('taffy.core.baseRepresentation',local.meta.fullname);
	}

	function withStatus_sets_status_code(){
		variables.representation.withStatus(42);
		assertEquals(42, variables.representation.getStatus());
	}

	function withHeaders_sets_headers(){
		local.h = { 'x-dude'='dude!'};
		variables.representation.withHeaders(local.h);
		assertEquals(true, structKeyExists(variables.representation.getHeaders(), "x-dude"));
	}

}
