<cfcomponent extends="baseTest">

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
			local.result = apiCall("get", "/echo/1.json?foo=bar", "");
			debug(local.result);
			debug(application);
			assertEquals(999, local.result.responseHeader.status_code);
		}

		function custom_headers_work(){
			local.result = apiCall("get", "/echo/-1.json", "");
			debug(local.result);
			assertEquals(true, structKeyExists(local.result.responseHeader, "x-dude"));
		}

		function global_headers_work(){
			local.result = apiCall("get", "/echo/1.json", "");
			debug(local.result);
			assertEquals(true, structKeyExists(local.result.responseHeader, "x-foo-globalheader"));
		}

		function uri_regexes_are_correct(){
			makePublic(variables.taffy, "convertURItoRegex");
			assertEquals("{""uriregex"":""\/a\/([^\\\/\\.]+)\/b(\\.[^\\.\\?]+)?$"",""tokens"":[""abc""]}", serializeJson(taffy.convertURItoRegex("/a/{abc}/b")));
		}

		function uri_matching_works_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json");
			assertEquals(local.result,'/echo/([^\/\.]+)(\.[^\.\?]+)?$');//fix after testing is working :-\
		}

		function uri_matching_works_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			assertEquals(local.result,'/echo/([^\/\.]+)(\.[^\.\?]+)?$');//fix after testing is working :-\
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
			assertEquals(true, structKeyExists(local.result, "foo") && local.result.foo == "bar");
			assertEquals(true, structKeyExists(local.result, "bar") && local.result.bar == "foo");
			assertEquals(true, structKeyExists(local.result, "id") && local.result.id == 16);
		}

		function properly_decodes_urlEncoded_put_request_body(){
			local.result = apiCall("put", "/echo/99.json", "foo=bar&check=mate");
			debug(local.result);
		}

		function properly_decodes_json_put_request_body(){
			local.result = apiCall("put", "/echo/99.json", '{"data":{"foo":"bar"}}');
			debug(local.result);
			if (!isJson(local.result.fileContent)){
				debug("expected json result but result was not json");
				assertEquals("json", "not json");
				return;
			}
			local.result = deserializeJSON(local.result.fileContent);
			assertEquals(true, structKeyExists(local.result, "foo") && local.result.foo == "bar");
			assertEquals(false, structKeyExists(local.result, "data"));
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
			assertEquals(true,!!findNoCase('woot', local.result.fileContent));//!! converts a +int into a bool true
		}

	</cfscript>

</cfcomponent>