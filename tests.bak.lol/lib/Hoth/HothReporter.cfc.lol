/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 01/12/2011

	HothReporter offers a simple Web UI to report the errors observed by Hoth.

	// Modifications :---------------------------------------------------------

*/
component
name='HothReporter'
accessors=false
output="false"
{
	public Hoth.HothReporter function init (HothConfig)
	{
		// If a config object was not provided we
		// will use our default.
		variables.Config = (structKeyExists(arguments, 'HothConfig'))
			? arguments.HothConfig
			: new Hoth.config.HothConfig();

		VARIABLES._NAME = 'Hoth_' & variables.Config.getApplicationName();
		
		variables.exceptionKeys 	= ['detail','type','tagcontext','stacktrace','message'];// Required exception keys
		variables.logPathIsRelative = variables.Config.getLogPathIsRelative();
		variables.paths.LogPath 	= variables.Config.getLogPathExpanded();				// Get the root location for our logging.
		variables.paths.Exceptions 	= variables.Config.getPath('exceptions');				// Track the unique exceptions.
		variables.paths.Incidents 	= variables.Config.getPath('incidents');				// Track the hits per exception.
		variables.paths.Report 		= variables.Config.getPath('exceptionReport');			// The actual report
		variables.paths.Activity 	= variables.Config.getPath('exceptionReportActivity');	// Track when we save things. Helps understand volume.
		//variables.paths.Index 	= variables.Config.getPath('exceptionIndex');			// Tracks the exception keys to prevent duplication

		return this;
	}

	/** Quick report. Really a work in process.
	*	@exception Accepts a hash value or 'all'
	**/
	public struct function report (required string exception)
	{
		if (arguments.exception=='all')
		{
			return generateExceptionIndex();
		} else {
			local.filepath = variables.paths.Exceptions & '/' & arguments.exception;

			local.exception = (fileExists(local.filepath))
			? fileRead(local.filepath)
			: serializeJSON ({'message'="That report no longer exists."});

			return deserializeJSON (local.exception);
		}
	}

	/** Quick report. Really a work in process.
	*	@exception Accepts a hash value or 'all'
	**/
	public array function delete (required string exception)
	{

		local.response = [];
		if (arguments.exception == 'all')
		{
			lock name=VARIABLES._NAME timeout=variables.Config.getTimeToLock() type="exclusive" {
				directoryDelete(variables.paths.Exceptions, true);
				directoryDelete(variables.paths.Incidents, true);
				directoryCreate(variables.paths.Exceptions);
				directoryCreate(variables.paths.Incidents);
			}
		} else {			local.exceptionPath = variables.paths.Exceptions & '/' & arguments.exception;
			local.incidentPath = variables.paths.Incidents & '/' & arguments.exception;

			local.response = [];

			if (fileExists(local.exceptionPath))
			{
				fileDelete(local.exceptionPath);
				arrayAppend(local.response, "Exception file deleted.");
			} else {
				arrayAppend(local.response, "Exception file did not exist!");
			}
			if (fileExists(local.incidentPath))
			{
				fileDelete(local.incidentPath);
				arrayAppend(local.response, "Incident record file deleted.");
			} else {
				arrayAppend(local.response, "Incident record file not exist!");
			}
			return local.response;
		}
	}

	/** Return the report's view **/
	public string function getReportView () {
		local.view = fileRead(expandPath('/Hoth') & '/views/report.html');

		// Replace the Hoth URL
		return replaceNoCase(
			 local.view
			,'${HOTH_REPORT_URL}'
			,variables.Config.getHothReportURL());
	}

	// -------------------------------------------------------------------------
	private struct function generateExceptionIndex() {
		// Read our file system
		local.exceptions = directoryList (variables.paths.Exceptions,false);
		local.incidents = directoryList (variables.paths.Exceptions,false);

		local.report = {};
		for (i=1;i LTE ArrayLen(local.exceptions);i=i+1) {

			local.instance = {};
			local.instance.filename =
			listLast(local.exceptions[i],'\/');

			if (left(local.instance.filename, 1) != '_')
			{
				//local.instance.exceptionDetail =
				//fileRead (local.exceptions[i]);

				if (!fileExists(variables.paths.Incidents & '/' & local.instance.filename))
				{
					local.instances = '';
				} else {
					local.instances =
					fileRead(variables.paths.Incidents & '/' & local.instance.filename);
				}

				local.instance.incidentcount = listLen(local.instances,chr(10));

				// Save our report
				local.report[local.instance.filename] = local.instance;
			}
		}

		return local.report;
	}
}