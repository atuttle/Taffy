<cfcomponent extends="base">
	<cfscript>

		function test_hoth(){
			var mockHoth = mock();
			var hothAdapter = '';
			var fakeError = {};

			//setup the behaviors we're expecting the adapter to run
			mockHoth.track('{struct}');

			//create hoth adapter to test
			hothAdapter = createObject("component", "taffy.bonus.LogToHoth").init(
				"taffy.examples.api_hoth.resources.HothConfig",
				mockHoth
			);

			//fake error
			fakeError.message = "This is a test error";
			fakeError.detail = "Rubber Baby Buggy Bumper";
			hothAdapter.saveLog(fakeError);

			mockHoth.verify().track('{struct}');
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
