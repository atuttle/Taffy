<cfsetting requesttimeout="600" />

<cfinvoke component="mxunit.runner.DirectoryTestSuite"
          method="run"
          directory="#expandPath('/Taffy/tests/tests')#"
          componentPath="Taffy.tests.tests"
          recurse="true"
          returnvariable="results" />

<cfoutput> #results.getResultsOutput('extjs')# </cfoutput>
