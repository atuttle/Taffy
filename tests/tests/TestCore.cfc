<cfcomponent extends="baseTest">

	<cfscript>

		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
		}

		function properly_notifies_unimplemented_mimes(){
			makePublic(variables.taffy, "mimeSupported");
			debug(variables.taffy);
			debug(application);
			assertFalse(taffy.mimeSupported("DoesNotExist"), "When given a mime type that should not exist, Taffy reported that it did.");
		}

		function properly_notifies_implemented_mimes(){
			makePublic(variables.taffy, "mimeSupported");
			makePublic(variables.taffy, "inspectMimeTypes");
			debug(variables.taffy);
			variables.taffy.inspectMimeTypes('taffy.core.nativeJsonRepresentation');
			assertTrue(taffy.mimeSupported("json"), "When given a mime type that should be supported, Taffy reported that it was not.");
		}

		function json_result_is_json(){
			local.result = apiCall ("get","/echo/2.json","bar=foo");
			debug(local.result);
			assertTrue(isJson(local.result.fileContent), "Expected JSON content back but was not able to identify it as such.");
		}

		function custom_status_is_returned(){
			local.result = apiCall("get", "/echo/1.json?foo=bar", "");
			debug(local.result);
			debug(application);
			assertEquals(999, local.result.responseHeader.status_code, "Expected status code 999 but got something else.");
		}

		function custom_headers_work(){
			local.result = apiCall("get", "/echo/-1.json", "");
			debug(local.result);
			assertTrue(structKeyExists(local.result.responseHeader, "x-dude"), "Expected response header `x-dude` but it was not included.");
		}

		function global_headers_work(){
			local.result = apiCall("get", "/echo/1.json", "");
			debug(local.result);
			assertTrue(structKeyExists(local.result.responseHeader, "x-foo-globalheader"), "Expected response header `x-foo-globalheader` but it was not included.");
		}

		function uri_regexes_are_correct(){
			makePublic(variables.taffy, "convertURItoRegex");
			assertEquals("{""uriregex"":""\/a\/([^\\\/\\.]+)\/b(\\.[^\\.\\?]+)?$"",""tokens"":[""abc""]}", serializeJson(taffy.convertURItoRegex("/a/{abc}/b")), "The expected result of the conversion did not match the actual result.");
		}

		function uri_matching_works_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json");
			debug(local.result);
			assertEquals('/echo/([^\/\.]+)(\.[^\.\?]+)?$', local.result);
		}

		function uri_matching_works_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			debug(local.result);
			assertEquals('/echo/([^\/\.]+)(\.[^\.\?]+)?$', local.result);
		}

		function request_parsing_works(){
			makePublic(variables.taffy,"buildRequestArguments");
			local.result = variables.taffy.buildRequestArguments(
				regex = '/echo/([^\/\.]+)(\.[^\.\?]+)?$',
				tokenNamesArray = ["id"],
				uri = '/echo/16',
				queryString = 'foo=bar&bar=foo',
				headers = {}
			);
			debug(local.result);
			assertTrue(structKeyExists(local.result, "foo") && local.result.foo == "bar", "Missing or incorrect value for key `foo`.");
			assertTrue(structKeyExists(local.result, "bar") && local.result.bar == "foo", "Missing or incorrect value for key `bar`.");
			assertTrue(structKeyExists(local.result, "id") && local.result.id == 16, "Missing or incorrect value for key `id`.");
		}

		function properly_decodes_urlEncoded_put_request_body(){
			local.result = apiCall("put", "/echo/99.json", "foo=bar&check=mate");
			debug(local.result);
			if (!isJson(local.result.fileContent)){
				fail("Result was not JSON");
				return;
			}
			local.result = deserializeJSON(local.result.fileContent);
			assertTrue(structKeyExists(local.result, "foo") && local.result.foo == "bar", "Missing or incorrect value for key `foo`.");
			assertTrue(structKeyExists(local.result, "check") && local.result.check == "mate", "Missing or incorrect value for key `check`.");
		}

		function properly_decodes_json_put_request_body(){
			local.result = apiCall("put", "/echo/99.json", '{"data":{"foo":"bar"}}');
			debug(local.result);
			if (!isJson(local.result.fileContent)){
				fail("Result was not JSON");
				return;
			}
			local.result = deserializeJSON(local.result.fileContent);
			assertTrue(structKeyExists(local.result, "foo") && local.result.foo == "bar", "Missing or incorrect value for key `foo`.");
			assertFalse(structKeyExists(local.result, "data"), "DATA element was not supposed to be included in arguments, but was included.");
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
			local.result = apiCall("delete", "/echo/2.json", "foo=bar");
			debug(local.result);
			assertEquals(405, local.result.responseHeader.status_code);
		}

		function test_onTaffyRequest_allow(){
			local.result = apiCall("get","/echo/12.json","refuse=false");
			debug(local.result);
			assertEquals(999,local.result.responseHeader.status_code);
		}

		function test_onTaffyRequest_deny(){
			local.result = apiCall("get","/echo/12.json","refuse=true");
			debug(local.result);
			assertEquals(405,local.result.responseHeader.status_code);
		}

		function external_file_request_passes_through(){
			local.result = getUrl('http://localhost/taffy/tests/someFolder/someOtherFile.cfm');
			debug(local.result);
			assertTrue(findNoCase('woot', local.result.fileContent), "Was not able to get the DMZ file.");
		}

	</cfscript>

</cfcomponent>