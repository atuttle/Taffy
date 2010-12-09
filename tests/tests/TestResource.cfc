component extends="mxunit.framework.TestCase" {

	function beforeTests(){
		variables.taffy = createObject("component","taffy.tests.Application");
		variables.resource = createObject("component", "taffy.core.resource");
	}

	function representationOf_returns_repClass(){
		//this test does not account for nested inheretance, should be enhanced to at some point
		makePublic(variables.resource, "representationOf");
		local.result = variables.resource.representationOf(10);
		local.meta = getMetadata(local.result);
		debug(local.meta);
		assertEquals('taffy.core.baseRepresentation',local.meta.extends.fullName);
	}

}