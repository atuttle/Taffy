<cfsetting showdebugoutput="false" />
<cfscript>
	testsDir = expandPath('/Taffy/tests/tests');
	componentPath = 'Taffy.tests.tests';

	suite = createObject('mxunit.framework.TestSuite');
	files = createObject('mxunit.runner.DirectoryTestSuite').getTests(directory=testsDir, componentPath=componentPath);

	for (i = 1; i <= arrayLen(files); i++){
		suite.addAll(files[i]);
	}

	tests = suite.suites();

	for (t in tests){
		tests[t] = tests[t].methods;
	}
</cfscript>
<cfcontent reset="true" type="application/json; charset=UTF-8" /><cfoutput>#serializeJson(tests)#</cfoutput><cfabort/>
