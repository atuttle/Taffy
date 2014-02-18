<cfcomponent extends="base">

	<cffunction name="setup">
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />
		<cfhttp method="GET" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##local.apiRootURL#/index.cfm?#application._taffy.settings.reloadkey#=#application._taffy.settings.reloadPassword#" />
	</cffunction>

	<cfscript>
		function beforeTests(){
			variables.taffy = createObject("component","taffy.tests.Application");
			makePublic(variables.taffy, "getBeanFactory");
			variables.factory = variables.taffy.getBeanFactory();
			variables.factory.loadBeansFromPath( expandPath('/taffy/tests/resources'), 'taffy.tests.resources', expandPath('/taffy/tests/resources'), true );
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

		function returns_etag_header(){
			local.result = apiCall("get", "/echo/foo.json", "");
			debug(local.result);
			assertTrue(structKeyExists(local.result.responseHeader, "Etag"));
			assertEquals("99805", local.result.responseHeader.etag);
		}

		function returns_304_when_not_modified(){
			local.h = {};
			local.h['if-none-match'] = "99805";
			local.result = apiCall("get", "/echo/foo.json", "", local.h);
			debug(local.result);
			assertEquals(304, val(local.result.responseHeader.status_code));
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
			assertEquals( "^/a/([^\/]+)/b((?:\.)[^\.\?\/]+)?\/?$", local.result["uriregex"], "Resulted regex did not match expected. (assert 1)");
			assertEquals( 1, arrayLen(local.result["tokens"]), "assert 2" );
			assertEquals( "abc", local.result["tokens"][1], "assert 3" );

			local.result2 = taffy.convertURItoRegex("/a/{abc}");
			debug(local.result2);
			assertEquals( "^/a/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$", local.result2["uriregex"], "Resulted regex did not match expected.");
			assertEquals( 1, arrayLen(local.result2["tokens"]) );
			assertEquals( "abc", local.result2["tokens"][1] );

			//custom regexes for tokens
			local.result3 = taffy.convertURItoRegex("/a/{b:[a-z]+(?:42){1}}");
			debug(local.result3);
			assertEquals( "^/a/([a-z]+(?:42){1})((?:\.)[^\.\?\/]+)?\/?$", local.result3["uriregex"], "Resulted regex did not match expected. (assert 7)");
			assertEquals( 1, arrayLen(local.result3["tokens"]), "assert 8" );
			assertEquals( "b", local.result3["tokens"][1], "assert 9" );

			local.result4 = taffy.convertURItoRegex("/a/{b:[0-4]{1,7}(?:aaa){1}}/c/{d:\d+}");
			debug(local.result4);
			assertEquals( "^/a/([0-4]{1,7}(?:aaa){1})/c/(\d+)((?:\.)[^\.\?\/]+)?\/?$", local.result4["uriregex"], "Resulted regex did not match expected. (assert 10)");
			assertEquals( 2, arrayLen(local.result4["tokens"]), "assert 11" );
			assertEquals( "b", local.result4["tokens"][1], "assert 12" );
			assertEquals( "d", local.result4["tokens"][2], "assert 13" );
		}

		function uri_matching_works_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json");
			debug(local.result);
			assertEquals('^/echo/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$', local.result);
		}

		function uri_matching_works_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			debug(local.result);
			assertEquals('^/echo/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$', local.result);
		}

		function uri_matching_works_with_trailing_slash_with_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3.json/");
			debug(local.result);
			assertEquals('^/echo/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$', local.result);
		}

		function uri_matching_works_with_trailing_slash_without_extension(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3/");
			debug(local.result);
			assertEquals('^/echo/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$', local.result);
		}

		function uri_matching_is_sorted_so_static_URIs_take_priority_over_tokens(){
			makePublic(variables.taffy, "matchURI");
			local.result = variables.taffy.matchURI("/echo/3");
			debug(local.result);
			assertEquals('^/echo/(?:(?:([^\/\.]+)(?:\.)([a-za-z0-9]+))\/?|([^\/\.]+))((?:\.)[^\.\?\/]+)?\/?$', local.result);
			local.result = variables.taffy.matchURI("/echo/towel");
			debug(local.result);
			assertEquals('^/echo/towel((?:\.)[^\.\?\/]+)?\/?$', local.result);
		}

		function request_parsing_works(){
			makePublic(variables.taffy,"buildRequestArguments");
			local.result = variables.taffy.buildRequestArguments(
				regex = '/echo/([^\/\.]+)$',
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

		function returns_error_when_default_mime_not_implemented(){
			makePublic(variables.taffy, "setDefaultMime");
			variables.taffy.setDefaultMime("DoesNotExist");
			local.result = apiCall("get", "/echo/2", "foo=bar");
			debug(local.result);
			assertEquals(400, local.result.responseHeader.status_code);
			assertEquals("Your default mime type (DoesNotExist) is not implemented", local.result.responseHeader.explanation);
		}

		function returns_error_when_requested_mime_not_supported(){
			makePublic(variables.taffy, "setDefaultMime");
			variables.taffy.setDefaultMime("application/json");
			local.h = structNew();
			local.h['Accept'] = "application/NOPE";
			local.result = apiCall ("get","/echo/2","foo=bar", local.h);
			debug(local.result);
			assertEquals(400, local.result.responseHeader.status_code);
			assertEquals("Requested mime type is not supported (application/NOPE)", local.result.responseHeader.explanation);
		}

		function extension_takes_precedence_over_accept_header(){
			makePublic(variables.taffy, "setDefaultMime");
			variables.taffy.setDefaultMime("text/json");
			local.headers = structNew();
			local.headers["Accept"] = "text/xml";
			local.result = apiCall("get","/echo/2.json","foo=bar",local.headers);
			debug(local.result);
			assertEquals(999, local.result.responseHeader.status_code);
			assertTrue(isJson(local.result.fileContent));
		}

		function allows_regex_as_final_url_value(){
			makePublic(variables.taffy, "buildRequestArguments");
			local.headers = structNew();
			local.headers.Accept = "application/json";
			local.result = variables.taffy.buildRequestArguments(
				"^/echo/([a-zA-Z0-9_\-\.\+]+@[a-zA-Z0-9_\-\.]+\.?[a-zA-Z]+)((?:\.)[^\.\?]+)?$",
				["id"],
				"/echo/foo@bar.com",
				"",
				local.headers
			);
			debug(local.result);
			assertTrue(local.result._taffy_mime eq "json", "Did not detect desired return format correctly.");

			//full integration test for a@b.c.json
			local.result = apiCall("get", "/echo_regex/12345.json", "", {});
			debug(local.result);
			assert(isJson(local.result.fileContent), "response was not json");
			local.response = deserializeJSON(local.result.fileContent);
			assertEquals("12345", local.response.id);

			//full integration test for a@b.c (no .json, but with headers)
			local.result = apiCall("get", "/echo_regex/12345", "", local.headers);
			debug(local.result);
			assert(isJson(local.result.fileContent), "response was not json");
			local.response = deserializeJSON(local.result.fileContent);
			assertEquals("12345", local.response.id);
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

			local.headers["X-HTTP-Method-Override"] = "PUT";
			local.result = apiCall("post","/echo/tunnel/12.json","", local.headers);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );
			assertEquals("put", local.deserializedContent.actualMethod);
		}

		function tunnel_DELETE_through_POST(){
			var local = {};

			local.headers["X-HTTP-Method-Override"] = "DELETE";
			local.result = apiCall("post","/echo/tunnel/12.json","", local.headers);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );
			assertEquals("delete", local.deserializedContent.actualMethod);
		}

		function put_body_is_mime_content(){
			var local = {};

			local.result = apiCall(
				"put",
				"/echo/12.json",
				'{"foo":"The quick brown fox jumped over the lazy dog."}'
			);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );

			// The service response should contain only the ID parameter, and not anything parsed from the body
			assertEquals("foo,id,password,username", listSort(structKeylist(local.deserializedContent), "textnocase"));
			assertEquals(12, local.deserializedContent["id"]);
			assertEquals("The quick brown fox jumped over the lazy dog.", local.deserializedContent["foo"]);
		}

		function put_body_is_url_encoded_params(){
			var local = {};

			makePublic(variables.taffy, "setDefaultMime");
			variables.taffy.setDefaultMime("application/json");
			local.result = apiCall(
				"put",
				"/echo/12.json",
				"foo=yankee&bar=hotel&baz=foxtrot"
			);
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);

			local.deserializedContent = deserializeJSON( local.result.fileContent );
			debug( local.deserializedContent );

			// The service response should contain the ID parameter and all parsed form fields from the body
			assertEquals("bar,baz,foo,id,password,username", listSort(structKeylist(local.deserializedContent), "textnocase"));
			assertEquals(12, local.deserializedContent["id"]);
			assertEquals("yankee", local.deserializedContent["foo"]);
			assertEquals("hotel", local.deserializedContent["bar"]);
			assertEquals("foxtrot", local.deserializedContent["baz"]);
		}

		function get_queryString_keys_without_values_returns_empty_string() {
			makePublic(variables.taffy, "buildRequestArguments");

			var returnedArguments = variables.taffy.buildRequestArguments(
				regex = "^/testResource/$",
				tokenNamesArray = [],
				uri = "/testResource/",
				queryString = "keyOne=valueOne&keyTwo=&keyThree=valueThree",
				headers = {}
			);

			assertEquals("", returnedArguments["keyTwo"]);
		}

		function returns_allow_header_for_405(){
			local.result = apiCall("delete","/echo/12.json","");
			debug(local.result);
			assertEquals(405,local.result.responseHeader.status_code);
			assertTrue(structKeyExists(local.result.responseHeader, "allow"),"Expected ALLOW header, but couldn't find it");
		}

		function returns_allow_header_for_get_200(){
			local.result = apiCall("get","/echo/tunnel/12.json","");
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);
			assertTrue(structKeyExists(local.result.responseHeader, "allow"),"Expected ALLOW header, but couldn't find it");
		}

		function returns_allow_header_for_post_201(){
			local.result = apiCall("post","/echo/tunnel/12.json","");
			debug(local.result);
			assertEquals(201,local.result.responseHeader.status_code);
			assertTrue(structKeyExists(local.result.responseHeader, "allow"),"Expected ALLOW header, but couldn't find it");
		}

		function returns_allow_header_for_put_200(){
			local.result = apiCall("put","/echo/tunnel/12.json","");
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);
			assertTrue(structKeyExists(local.result.responseHeader, "allow"),"Expected ALLOW header, but couldn't find it");
		}

		function returns_allow_header_for_delete_200(){
			local.result = apiCall("delete","/echo/tunnel/12.json","");
			debug(local.result);
			assertEquals(200,local.result.responseHeader.status_code);
			assertTrue(structKeyExists(local.result.responseHeader, "allow"),"Expected ALLOW header, but couldn't find it");
		}

		function can_pass_data_from_onTaffyRequest_to_resource(){
			local.result = apiCall("get", "/echo/dude.json", "hulk=smash");
			debug(local.result);
			local.body = deserializeJSON(local.result.fileContent);
			assertTrue(structKeyExists(local.body, "dataFromOTR"));
			assertTrue(local.body.dataFromOTR eq "who let the hulk out?!");
		}

		function reload_on_every_request_setting_works(){
			application._taffy.settings.reloadOnEveryRequest = false;
			local.result = apiCall("get", "/echo/dude.json", "");
			debug(local.result);
			assertFalse(structKeyExists(local.result.responseheader, "X-TAFFY-RELOADED"), "Expected reload header to be missing, but it was sent.");
			application._taffy.settings.reloadOnEveryRequest = true;
			local.result2 = apiCall("get", "/echo/dude.json", "");
			debug(local.result2);
			assertTrue(structKeyExists(local.result2.responseheader, "X-TAFFY-RELOADED"), "Expected reload header to be sent, but it was missing.");
		}

		function returns_error_when_resource_throws_exception(){
			local.result = apiCall("get", "/throwException.json", "");
			debug(local.result);
			assertEquals(500, local.result.responseHeader.status_code);
			assertTrue( isJson( local.result.fileContent ), "Response body was not json" );
		}

		function basic_auth_credentials_found(){
			local.result = apiCall("get", "/basicauth.json", "", {}, "Towel:42");
			debug(local.result);
			assertTrue(isJson(local.result.fileContent));
			local.data = deserializeJSON(local.result.fileContent);
			assertTrue(structKeyExists(local.data, "username"));
			assertEquals("Towel", local.data.username);
			assertTrue(structKeyExists(local.data, "password"));
			assertEquals("42", local.data.password);
		}

		function getHostname_returns_not_blank(){
			local.hostname = variables.taffy.getHostname();
			debug(local.hostname);
			assertNotEquals( "", local.hostname );
		}

		function envConfig_is_applied(){
			debug( application._taffy.settings.reloadPassword );
			assertEquals( "dontpanic", application._taffy.settings.reloadPassword );
		}

		function use_endpointURLParam_in_GET(){
			local.result = apiCall('get','?#application._taffy.settings.endpointURLParam#=/echo/2606.json','');

			debug(local.result);
			assertEquals(999,val(local.result.statusCode));
		}

		function use_endpointURLParam_in_POST(){
			local.result = apiCall('post','?#application._taffy.settings.endpointURLParam#=/echo/2606.json','bar=foo');

			debug(local.result);
			assertEquals(200,val(local.result.statusCode));
		}

		function use_endpointURLParam_in_PUT(){
			local.result = apiCall('put','?#application._taffy.settings.endpointURLParam#=/echo/2606.json','bar=foo');

			debug(local.result);
			assertEquals(200,val(local.result.statusCode));
		}

		function use_endpointURLParam_in_DELETE(){
			local.result = apiCall('delete','?#application._taffy.settings.endpointURLParam#=/echo/tunnel/2606.json','');

			debug(local.result);
			assertEquals(200,val(local.result.statusCode));
		}

		function allows_dashboard_when_enabled(){
			var restore = application._taffy.settings.disableDashboard;
			application._taffy.settings.disableDashboard = false;
			local.result = apiCall("get", "/", "");
			debug(local.result);
			assertEquals(200, val(local.result.statusCode));

			application._taffy.settings.disableDashboard = restore;
		}

		function returns_403_at_root_when_dashboard_disabled_with_no_redirect(){
			var restore = application._taffy.settings.disableDashboard;
			application._taffy.settings.disableDashboard = true;
			local.result = apiCall("get", "/", "");
			debug(local.result);
			assertEquals(403, val(local.result.statusCode));

			application._taffy.settings.disableDashboard = restore;
		}

		function returns_302_at_root_when_dashboard_disabled_with_redirect(){
			var restore1 = application._taffy.settings.disableDashboard;
			var restore2 = application._taffy.settings.disabledDashboardRedirect;
			application._taffy.settings.disableDashboard = true;
			application._taffy.settings.disabledDashboardRedirect = 'http://google.com';
			local.result = apiCall("get", "/", "");
			debug(local.result);
			assertEquals(302, val(local.result.statusCode));
			assertTrue(structKeyExists(local.result.responseHEader, "location"));
			assertEquals(application._taffy.settings.disabledDashboardRedirect, local.result.responseHeader.location);

			application._taffy.settings.disableDashboard = restore1;
			application._taffy.settings.disabledDashboardRedirect = restore2;
		}

		function properly_returns_wrapped_jsonp(){
			application._taffy.settings.jsonp = "callback";
			local.result = apiCall("get", "/echo/dude.json?callback=zomg", '');
			debug(local.result);
			assertEquals('zomg(', left(local.result.fileContent, 5), "Does not begin with call to jsonp callback");
			assertEquals(");", right(local.result.fileContent, 2), "Does not end with `);`");
		}

		function properly_handles_arbitrary_cors_headers(){
			//see: https://github.com/atuttle/Taffy/issues/144
			application._taffy.settings.allowCrossDomain = true;
			local.h = { "Access-Control-Request-Headers" = "goat, pigeon, man-bear-pig"};
			local.result = apiCall("get", "/echo/dude.json", "", local.h);
			debug(local.result);
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "goat");
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "pigeon");
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "man-bear-pig");
		}

		function properly_handles_arbitrary_cors_headers_on_error(){
			//see: https://github.com/atuttle/Taffy/issues/159
			application._taffy.settings.allowCrossDomain = true;
			local.h = { "Access-Control-Request-Headers" = "goat, pigeon, man-bear-pig"};
			local.result = apiCall("get", "/throwException.json", "", local.h);
			debug(local.result);
			assertTrue(structKeyExists(local.result.responseHeader, "Access-Control-Allow-Origin"));
			assertTrue(structKeyExists(local.result.responseHeader, "Access-Control-Allow-Methods"));
			assertTrue(structKeyExists(local.result.responseHeader, "Access-Control-Allow-Headers"));
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "goat");
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "pigeon");
			assertTrue(local.result.responseHeader["Access-Control-Allow-Headers"] contains "man-bear-pig");
		}

		function non_struct_json_body_sent_to_resource_as_underscore_body(){
			//see: https://github.com/atuttle/Taffy/issues/169
			local.result = apiCall("post", "/echo/5", "[1,2,3]");
			debug(local.result);
			local.response = deserializeJSON(local.result.fileContent);
			assertTrue(structKeyExists(local.response, "_body"));
			assertTrue(isArray(local.response._body));
			assertTrue(arrayLen(local.response._body) == 3);
		}
	</cfscript>


	<cffunction name="can_upload_a_file">
		<cfset var local = structNew() />
		<cfset local.apiRootURL	= getDirectoryFromPath(cgi.script_name) />
		<cfset local.apiRootURL	= listDeleteAt(local.apiRootURL,listLen(local.apiRootURL,'/'),'/') />
		<cfhttp
			url="http://#cgi.server_name#:#cgi.server_port##local.apiRootURL#/index.cfm/upload"
			method="post"
			result="local.uploadResult">
			<cfhttpparam type="file" name="img" file="#expandPath('/taffy/tests/tests/upload.png')#" />
		</cfhttp>
		<cfset debug(local.uploadResult) />
		<cfset assertTrue(local.uploadResult.statusCode eq "200 OK", "Did not return status 200") />
	</cffunction>

</cfcomponent>