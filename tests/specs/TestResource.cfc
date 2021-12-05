component extends="testbox.system.BaseSpec" {

	function beforeAll(){
		if ( !structKeyExists(application, "_taffy") ){
			var app = createObject("taffy.tests.api.Application");
			app.onApplicationStart();
		}
		application._taffy.settings.serializer = 'taffy.core.nativeJsonSerializer';
		variables.mockResource = new taffy.tests.api.resources.echoMember();
	}

	function run(){

		describe("taffy.core.resource", function(){

			describe("representationOf/rep", function(){
				it("returns a class that extends taffy.core.baseSerializer", function(){
					var response = variables.mockResource.rep(1);
					// debug( response );
					expect(eventuallyInherits( getMetadata( response ), 'taffy.core.baseSerializer' )).toBeTrue();
				});
			});


			describe("queryToArray", function(){
				it("respects query column case", function(){
					makePublic(variables.mockResource, "queryToArray", "public_queryToArray");

					var before = QueryNew("Foo,Bar");
					queryAddRow(before);
					querySetCell(before, "Foo", 42, 1);
					querySetCell(before, "Bar", "fubar", 1);
					// debug(before);
					var after = variables.mockResource.public_queryToArray(before);
					// debug(after);
					var keyList = structKeyList(after[1]);
					var serialized = serializeJSON(after);
					// debug(serialized);

					// debug(keyList);
					expect( (keyList == "Foo,Bar" || keyList == "Bar,Foo") ).toBeTrue();
					// debug(serialized);
					expect( (serialized == '[{"Foo":42,"Bar":"fubar"}]') || (serialized == '[{"Bar":"fubar","Foo":42}]') ).toBeTrue();
				});
			});

		});

	}

	/* recursive method used to check entire inheritance tree to find that a certain parent class exists somewhere within it */
	private boolean function eventuallyInherits(required struct md, required string class) {
		if (structKeyExists(md, "fullname") && md.fullname eq class) {
				return true;
		} else {
			if (structKeyExists(md, "extends")) {
				return eventuallyInherits(md.extends, class);
			} else {
				return false;
			}
		}
	}

}
