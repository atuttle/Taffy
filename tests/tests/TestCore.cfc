<cfcomponent extends="mxunit.framework.TestCase">

	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
		}

		function properly_notifies_unimplemented_mimes(){
			makePublic(variables.taffy, "mimeSupported");
			debug(variables.taffy);
			debug(application);
			assertEquals(false, taffy.mimeSupported("DoesNotExist"));
		}

		function properly_notifies_implemented_mimes(){
			makePublic(variables.taffy, "mimeSupported");
			makePublic(variables.taffy, "inspectMimeTypes");
			debug(variables.taffy);
			variables.taffy.inspectMimeTypes('taffy.core.nativeJsonRepresentation');
			assertEquals(true, taffy.mimeSupported("json"));
		}

		function json_result_is_json(){
			local.result = apiCall ("get","/echo/2.json","bar=foo");
			debug(local.result);
			assertEquals(true, isJson(local.result.fileContent));
		}

		function custom_status_is_returned(){
			local.result = apiCall("get", "/echo/1.json?status=200", "");
			debug(local.result);
			debug(application);
			assertEquals(202, local.result.responseHeader.status_code);
		}

		function custom_headers_work(){
			local.result = apiCall("get", "/echo/-1.json", "");
			debug(local.result);
			assertEquals(true, structKeyExists(local.result.responseHeader, "x-dude"));
		}

		function uri_regexes_are_correct(){
			makePublic(variables.taffy, "convertURItoRegex");
			assertEquals("{""uriregex"":""\/a\/([^\\\/\\.]+)\/b(\\.[^\\.\\?]+)?$"",""tokens"":[""abc""]}", serializeJson(taffy.convertURItoRegex("/a/{abc}/b")));
		}

		function uri_matching_works_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json");
			debug(local.result);
			assertEquals(true,false);//fix after testing is working :-\
		}

		function uri_matching_works_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			debug(local.result);
			assertEquals(true,false);//fix after testing is working :-\
		}

		function request_parsing_works(){
			makePublic(variables.taffy,"buildRequestArguments");
			local.result = variables.taffy.buildRequestArguments(
				regex = '/echo/([^\/\.]+)(\.[^\.\?]+)?$',
				tokenNamesArray = ["id"],
				uri = '/echo/16',
				queryString = 'foo=bar&bar=foo'
			);
			debug(local.result);
			assertEquals(true, structKeyExists(local.result, "foo") && local.result.foo == "bar");
			assertEquals(true, structKeyExists(local.result, "bar") && local.result.bar == "foo");
			assertEquals(true, structKeyExists(local.result, "id") && local.result.id == 16);
		}

		function throwError_sets_header(){
			makePublic(variables.taffy, "throwError");
			variables.taffy.throwError(400, "testing error throwing");
			//todo- remember how to check existing headers (I answered that on stackoverflow, actually!)
			assertEquals(true,false);
		}

		function returns_error_when_default_mime_not_supported(){
			variables.taffy.setDefaultMime("DoesNotExist");
			local.result = apiCall("get", "/echo/2", "foo=bar");
			debug(local.result);
			assertEquals(400, local.result.responseHeader.status_code);
		}

		function returns_error_when_requested_mime_not_supported(){
			local.result = apiCall ("get","/echo/2.negatory","foo=bar");
			debug(local.result);
			assertEquals(400, local.result.responseHeader.status_code);
		}

		function returns_405_for_unimplemented_verbs(){
			local.result = apiCall("put", "/echo/2.json", "foo=bar");
			debug(local.result);
			assertEquals(405, local.result.responseHeader.status_code);
		}

	</cfscript>

	<cffunction name="apiCall" access="private" output="false">
		<cfargument name="method" type="string"/>
		<cfargument name="uri" type="string"/>
		<cfargument name="query" type="string"/>
		<cfhttp method="#arguments.method#" url="http://localhost/taffy/tests/index.cfm#arguments.uri#?#arguments.query#" result="local.result"/>
		<cfreturn local.result />
	</cffunction>

</cfcomponent>