<cfcomponent extends="baseTest">
	<cfscript>
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