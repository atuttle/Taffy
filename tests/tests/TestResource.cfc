<cfcomponent extends="base">
	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			variables.resource = createObject("component", "taffy.core.resource");
		}

		function representationOf_returns_repClass(){
			application._taffy.settings.representationClass = "taffy.core.nativeJsonRepresentation";
			makePublic(variables.resource, "representationOf");
			local.result = variables.resource.representationOf(10);
			local.meta = getMetadata(local.result);
			debug(local.meta);
			assertEquals(true, eventuallyInherits(local.meta, 'taffy.core.baseRepresentation'));
		}

		function queryToArray_respects_column_case(){
			makePublic(variables.resource, "queryToArray");
			local.before = QueryNew("Foo,Bar");
			queryAddRow(local.before);
			querySetCell(local.before, "Foo", 42, 1);
			querySetCell(local.before, "Bar", "fubar", 1);
			debug(local.before);
			local.after = variables.resource.queryToArray(local.before);
			debug(local.after);
			local.keyList = structKeyList(local.after[1]);
			local.serialized = serializeJSON(local.after);
			debug(local.serialized);

			assertTrue( (local.keyList == "Foo,Bar" or local.keyList == "Bar,Foo"), 'column name case is not as expected');
			assertTrue( (local.serialized == '[{"Foo":42,"Bar":"fubar"}]') or (local.serialized == '[{"Bar":"fubar","Foo":42}]') );
		}

	</cfscript>

	<!--- recursive method used to check entire inheritance tree to find that a certain parent class exists somewhere within it --->
	<cffunction name="eventuallyInherits" access="private" output="false" returntype="boolean">
		<cfargument name="md" type="struct" required="true" />
		<cfargument name="class" type="string" required="true" />

		<cfscript>
			if (structKeyExists(md, "fullname") && md.fullname eq class) {
				return true;
			} else {
				if (structKeyExists(md, "extends"))
				{
					return eventuallyInherits(md.extends, class);
				} else {
					return false;
				}
			}
		</cfscript>
	</cffunction>
</cfcomponent>