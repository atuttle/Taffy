<cfcomponent extends="base">
	<cfscript>

		function test_hoth(){
			var mockHoth = getMockBox().createMock(className="Hoth.HothTracker", callLogging=true);
			var hothAdapter = '';
			var fakeError = {};
			var callLog = {};
			//setup the behaviors we're expecting the adapter to run
			//mockHoth.track('{struct}');
			mockHoth.$('track', true);
			//create hoth adapter to test
			hothAdapter = createObject("component", "taffy.bonus.LogToHoth").init(
				"taffy.examples.api_hoth.resources.HothConfig",
				mockHoth
			);

			//fake error
			fakeError.message = "This is a test error";
			fakeError.detail = "Rubber Baby Buggy Bumper";
			hothAdapter.saveLog(fakeError);

			callLog = mockHoth.$callLog();
			debug(callLog);
			assertTrue(structKeyExists(callLog, "track"), "should call track method");
			assertTrue(isStruct(callLog.track[1][1]), "args should be a struct");
			assertEquals(callLog.track[1][1].message, fakeError.message);

		}

		function test_BugLogHQ(){
			var blhqSettings = { bugLogListener = "http://#cgi.server_name#:#cgi.server_port#/tests/BugLogHQ/listeners/bugLogListenerREST.cfm" };
			var mockBLHQ = new bugLog.client.bugLogService(argumentCollection=blhqSettings);
			var blhqAdapter = '';
			var fakeError = {};
			fakeError.message = "This is a test error";
			fakeError.detail = "Rubber Baby Buggy Bumper";

			//remove bugLogHQ Application.cfc so we can override datasource definition
			if (fileExists("/bugLog/Application.cfc")) {
				fileDelete("/bugLog/Application.cfc");
			}

			mockBLHQ.init(argumentCollection=blhqSettings);

			blhqAdapter = createObject("component", "taffy.bonus.LogToBugLogHQ").init(
				config=blhqSettings,
				tracker=mockBLHQ
			);

			//fake error
			fakeError.message = "This is a test error";
			fakeError.detail = "Rubber Baby Buggy Bumper";
			blhqAdapter.saveLog(fakeError);


		}

	</cfscript>
</cfcomponent>
