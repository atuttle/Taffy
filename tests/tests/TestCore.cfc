<cfcomponent extends="base">

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

			local.result = taffy.convertURItoRegex("/a/{abc}/b");
			debug(local.result);
			/* Since CF8, 9, etc don't all serialize the same, we'll do this in a little longer form to be more portable
			assertEquals("{""uriregex"":""\/a\/([^\\\/\\.]+)\/b(\\.[^\\.\\?]+)?$"",""tokens"":[""abc""]}",
							serializeJson(local.result),
							"The expected result of the conversion did not match the actual result.");*/
			assertEquals( "^/a/([^\/]+)/b(\.[^\.\?]+)?$", local.result["uriregex"], "Resulted regex did not match expected.");
			assertEquals( 1, arrayLen(local.result["tokens"]) );
			assertEquals( "abc", local.result["tokens"][1] );

			local.result2 = taffy.convertURItoRegex("/a/{abc}");
			debug(local.result2);
			assertEquals( "^/a/([^\/]+)(\.[^\.\?]+)?$", local.result2["uriregex"], "Resulted regex did not match expected.");
			assertEquals( 1, arrayLen(local.result2["tokens"]) );
			assertEquals( "abc", local.result2["tokens"][1] );
		}
		function uri_matching_works_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json");
			debug(local.result);
			assertEquals('^/echo/([^\/]+)(\.[^\.\?]+)?$', local.result);
		}

		function uri_matching_works_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			debug(local.result);
			assertEquals('^/echo/([^\/]+)(\.[^\.\?]+)?$', local.result);
		}

		function request_parsing_works(){
			makePublic(variables.taffy,"buildRequestArguments");
			local.result = variables.taffy.buildRequestArguments(
				regex = '/echo/([^\/\.]+)(\.[^\.\?]+)?$',
				tokenNamesArray = listToArray("id"),
				uri = '/echo/16',
				queryString = 'foo=bar&bar=foo',
				headers = structNew()
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
				debug(local.result.fileContent);
				fail("Result was not JSON");
				return local.result.fileContent;
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

		function properly_decodes_json_post_request_body(){
			local.result = apiCall("post", "/echo/99.json", '{"data":{"foo":"bar"}}');
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
			local.result = getUrl('http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/taffy/tests/someFolder/someOtherFile.cfm');
			debug(local.result);
			assertTrue(findNoCase('woot', local.result.fileContent), "Was not able to get the DMZ file.");
		}

		function tunnel_PUT_through_POST(){
			var local = {};

			variables.taffy.setDefaultMime("text/json");
			local.headers["X-HTTP-Method-Override"] = "PUT";
			local.headers["Accept"] = "text/json";
			local.result = apiCall("post","/echo/tunnel/12","", local.headers);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );
			assertEquals("put", local.deserializedContent.actualMethod);
		}

		function tunnel_DELETE_through_POST(){
			var local = {};

			variables.taffy.setDefaultMime("text/json");
			local.headers["X-HTTP-Method-Override"] = "DELETE";
			local.headers["Accept"] = "text/json";
			local.result = apiCall("post","/echo/tunnel/12","", local.headers);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );
			assertEquals("delete", local.deserializedContent.actualMethod);
		}

		function put_body_is_mime_content(){
			var local = {};

			variables.taffy.setDefaultMime("text/json");
			// Override body content type to send XML packet
			local.headers["Accept"] = "text/json";
			local.headers["Content-Type"] = "application/json";
			local.result = apiCall(
				"put",
				"/echo/12",
				'{"foo":"The quick brown fox jumped over the lazy dog."}',
				local.headers
			);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );

			// The service response should contain only the ID parameter, and not anything parsed from the body
			assertEquals("id,foo", structKeylist(local.deserializedContent));
			assertEquals(12, local.deserializedContent["id"]);
			assertEquals("The quick brown fox jumped over the lazy dog.", local.deserializedContent["foo"]);
		}

		function put_body_is_url_encoded_params(){
			var local = {};

			variables.taffy.setDefaultMime("text/json");
			// Default Content-Type is "application/x-www-form-urlencoded"
			local.headers["Accept"] = "text/json";
			local.result = apiCall("put",
									"/echo/12",
									"foo=yankee&bar=hotel&baz=foxtrot",
									local.headers);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );

			// The service response should contain the ID parameter and all parsed form fields from the body
			assertEquals("bar,baz,foo,id", listSort(structKeylist(local.deserializedContent), "textnocase"));
			assertEquals(12, local.deserializedContent["id"]);
			assertEquals("yankee", local.deserializedContent["foo"]);
			assertEquals("hotel", local.deserializedContent["bar"]);
			assertEquals("foxtrot", local.deserializedContent["baz"]);
		}
		
		function get_queryString_keys_without_values_returns_empty_string() {
			makePublic(variables.taffy, "buildRequestArguments");
			
			var returnedArguments = variables.taffy.buildRequestArguments(
				regex = "/testResource/(\.[^\.\?]+)?$",
				tokenNamesArray = [],
				uri = "/testResource/",
				queryString = "keyOne=valueOne&keyTwo=&keyThree=valueThree",
				headers = {}
			);
			
			assertEquals("", returnedArguments["keyTwo"]);
		}
	</cfscript>

</cfcomponent>