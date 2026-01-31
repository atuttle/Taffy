<cfcomponent hint="automatic test suite runner">

	<cfset this.s_results = StructNew()>
	<cfset this.s_results.Errors = StructNew()>
	<cfset sep = createObject("java","java.lang.System").getProperty("file.separator")>

	<cffunction name="run" access="public" hint="runs a directory of tests" returntype="any" output="false">
		<cfargument name="directory" required="true" hint="directory of tests to run">
		<cfargument name="componentPath" required="false" hint="the component path to put in front of all tests found (i.e. 'com.blah'). If no path is passed, we'll attempt to discover it ourselves" default="">
		<cfargument name="recurse" required="false" type="boolean" default="true" hint="whether to recurse down the directory tree">
		<cfargument name="excludes" required="false" default="" hint="list of Tests, in cfc notation, to exclude. uses ListContains so it's as greedy as possible. Currently does not support ant-style syntax or whole-directory filtering">
		<cfargument name="refreshCache" required="false" default="false" hint="flag to indicate whether or not to refresh the CF cache of CFCs. Maybe needed if any of the tests in the directory have not yet been compiled - to do: prove" />

		<cfset var testResult = "">
		<cfset var files = "">
		<cfset var suite = createObject("component","mxunit.framework.TestSuite")>
		<cfset var i = 1>

		<cfset arguments.directory = normalizeDirectory(arguments.directory)>

		<cfif NOT len(arguments.componentPath)>
			<cfset arguments.componentPath = getComponentPath(arguments.directory, arguments.refreshCache)>
		</cfif>

		<cfset files = getTests(arguments.directory,arguments.componentPath,arguments.recurse,trim(arguments.excludes)) />

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cftry>
				<cfset suite.addAll(files[i])>

				<cfcatch>
					<cfset this.s_results.Errors[files[i]] = cfcatch>
				</cfcatch>
			</cftry>
		</cfloop>

		<cfset testResult = suite.run()>

		<cfset testResult.mergeErrorsIntoTestResult(this.s_results.Errors)>

		<cfreturn testResult>
	</cffunction>

	<cffunction name="getTests" access="private" output="false">
		<cfargument name="directory" required="true" hint="directory of tests to run">
		<cfargument name="componentPath" required="true" hint="the component path to put in front of all tests found (i.e. 'com.blah')">
		<cfargument name="recurse" required="false" default="true" type="boolean" hint="whether to recurse down the directory tree">
		<cfargument name="excludes" required="false" default="" hint="ant-style syntax for excluding single files or directories">
		<cfset var q_tests = getDirectoryQuery(directory,recurse)>
		<cfset var a_tests = ArrayNew(1)>
		<cfset var testPath = "">

		<cfloop query="q_tests">
			<cfset testPath = formatTestPath(arguments.directory, q_tests.directory & sep & q_tests.Name,arguments.componentPath)>

			<cfif accept(testPath,arguments.excludes)>
				<cftry>
					<!---
					  Compile first. This ensures that any new tests NOT found in the server cache get added.
					  This may actually be quicker than searching the array and then conditionally compiling.
					  Appears not to have much overhead, but, we should monitor anyway for large test runs.
					 --->
					<cfset createObject("component","#testPath#") />
				<cfcatch type="any"><!--- no worries ---></cfcatch>
			</cftry>
				<cfset ArrayAppend(a_tests,testPath)>
			</cfif>
		</cfloop>
		<cfreturn a_tests>
	</cffunction>

	<cffunction name="formatTestPath" access="private" output="false">
		<cfargument name="directory" required="true" hint="directory of tests to run">
		<cfargument name="fullFilePath">
		<cfargument name="componentPath" required="true" hint="the component path to put in front of all tests found (i.e. 'com.blah')">

		<cfset var formatted = replaceNoCase(fullFilePath,directory,"")>
		<cfset formatted =  reverse(  replace(reverse(formatted),"cfc.","")    )>
		<cfset formatted = componentPath & "." & formatted>
		<cfset formatted = reReplace(formatted, "(\\|/|\.){1,}" ,".","all")>
		<cfreturn formatted>
	</cffunction>

	<cffunction name="getDirectoryQuery" access="private" returntype="query" output="false">
		<cfargument name="directory" required="true" hint="directory of tests to run">
		<cfargument name="recurse" type="boolean" required="false" default="true" hint="whether to recurse down the directory tree">
		<cfset var files = "">
		<cfset var runnerUtils = "">

		<cfif not DirectoryExists(arguments.directory)>
			<cfthrow message="Directory #directory# does not exist">
		</cfif>

		<cfdirectory action="list" directory="#arguments.directory#" name="files" recurse="#arguments.recurse#" filter="*.cfc">

		<cfreturn files>
	</cffunction>

	<cffunction name="getCatastrophicErrors" output="false">
		<cfreturn this.s_results.Errors>
	</cffunction>

	<cffunction name="accept" hint="rudimentary initial implementation." access="private" output="false">
		<cfargument name="test" required="true">
		<cfargument name="excludes" required="true">

		<cfset var testName = ListLast(arguments.test,".")>
		<cfset var thisExclude = "">

		<cfif NOT reFindNoCase("^test",testName) AND NOT reFindNoCase("test$",testName)>
			<cfreturn false>
		</cfif>
		<cfif not len(excludes)>
			<cfreturn true>
		</cfif>

		<cfset arguments.test = ListChangeDelims(arguments.test,"/",".")>
		<cfloop list="#excludes#" index="thisExclude" delimiters=",">
			<cfset thisExclude = replace(thisExclude,"\","/")>
			<cfif reFindNoCase("\b#thisExclude#\b",arguments.test)>
				<cfreturn false>
			</cfif>
		</cfloop>
		<cfreturn true>
	</cffunction>

	<cffunction name="normalizeDirectory" hint="makes sure every directory has ending slashes" access="private" output="false">
		<cfargument name="Directory" type="string" required="true"/>
		<cfset var dir = createObject("java","java.io.File")>

		<cfif not DirectoryExists(arguments.directory)>
			<cfset arguments.directory = expandPath(arguments.directory) />
			<cfif not DirectoryExists(arguments.directory)>
				<cfthrow message="Directory #directory# does not exist">
			</cfif>
		</cfif>

		<cfset dir.init(arguments.directory)>
		<cfset arguments.directory = dir.getCanonicalPath()>
		<cfset arguments.directory = replaceList(arguments.directory,"/,\","#sep#,#sep#")>
		<cfset arguments.directory = arguments.directory & sep>
		<cfreturn arguments.directory>
	</cffunction>

	<cffunction name="getComponentPath" access="remote" returntype="string" hint="Given a directory path, returns the corresponding CFC package according to CFMX" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="refreshCache" type="boolean" required="false" default="false" />
		<cfscript>
		var explorer = createObject("component", "CFIDE.componentutils.cfcexplorer");
		var target = explorer.normalizePath(arguments.path);
		var cfcs = explorer.getcfcs(refreshCache); //true == refresh cache
		var cfc = "";
		var i = 1 ;
		var package = "";
		var cfcpath = "";

		for(i = 1; i lte arraylen(cfcs); i = i+1){
			cfc = cfcs[i];
			//Assumes that CF always stores path info with fwd slash
			//and strip last element to get path.
			cfcpath = ListDeleteAt(cfc.path, listlen(cfc.path,"/"), "/");

			//Array of structs. Doesn't seem possible to do binary search
			if(cfcpath eq target){

				package = cfc.package;
				break;
			}
		}

		return package;
		</cfscript>
	</cffunction>


	<cffunction name="getComponentPathx" access="remote" returntype="string" hint="Given a directory path, returns the corresponding CFC package" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="refreshCache" type="boolean" required="false" default="false" />

			<cfset var files = '' />
			<cfset var package = '' />

			<cfdirectory action="list" type="file" name="files" directory="#arguments.path#" filter="*.cfc" />

			<cfif files.recordCount>
				<cfset package = replace(normalizePath(files.directory), '/', '.', 'all') />
			</cfif>

			<cfreturn package />
		</cffunction>

	<cffunction name="normalizePath" access="public" returntype="string" output="false">
		<cfargument name="path" type="string" required="true" />

		<cfif not len(arguments.path)>
			<cfreturn arguments.path />
		</cfif>

		<cfset arguments.path = replace(arguments.path, '\', '/', 'all') />

		<cfif right(arguments.path, 1) eq '/'>
			<cfset arguments.path = left(arguments.path, len(arguments.path) - 1) />
		</cfif>

		<cfreturn arguments.path />
	</cffunction>
</cfcomponent>