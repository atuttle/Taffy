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
			var mockBLHQ = mock();
			var blhqAdapter = '';
			var blhqSettings = { bugLogListener = "http://localhost/bugLog/listeners/bugLogListenerREST.cfm" };
			var fakeError = {};

			mockBLHQ.notifyService('{string}', '{struct}');

			blhqAdapter = createObject("component", "taffy.bonus.LogToBugLogHQ").init(
				blhqSettings,
				mockBLHQ
			);

			//fake error
			fakeError.message = "This is a test error";
			fakeError.detail = "Rubber Baby Buggy Bumper";
			blhqAdapter.saveLog(fakeError);

			mockBLHQ.verify().notifyService('{string}', '{struct}');
		}

	</cfscript>
</cfcomponent>
