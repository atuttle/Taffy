component extends="baseTest" {

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
		assertEquals(true, eventuallyInherits(local.meta, 'taffy.core.baseRepresentation'));
	}

	//recursive method used to check entire inheritance tree to find that a certain parent class exists somewhere within it
	private function eventuallyInherits(md,class) output="false" returntype="boolean" {
		if (structKeyExists(md, "fullname") && md.fullname eq class){
			return true;
		}else{
			if (structKeyExists(md, "extends")){
				return eventuallyInherits(md.extends, class);
			}else{
				return false;
			}
		}
	}

}