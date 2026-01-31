/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 10/01/2010

	HothTracker is responsible for accepting a exception, tracking the frequency
	of the exception and alerting developers for new, unique exceptions.

	// Modifications :---------------------------------------------------------
	Modified		: 	12/13/2010 9:52:41 AM by Aaron Greenlee.
    				-	Now supporting ColdBox 3.0 RC1
*/
component
name='HothTracker'
accessors=false
{

	public Hoth.HothTracker function init (HothConfig) {
		// If a config object was not provided we
		// will use our default.
		variables.Config = (structKeyExists(arguments, 'HothConfig'))
			? arguments.HothConfig
			: new Hoth.object.HothConfig();

		VARIABLES._NAME = 'Hoth_' & variables.Config.getApplicationName();

		variables.exceptionKeys 	= ['detail','type','tagcontext','stacktrace','message'];			// Required exception keys
		variables.paths.LogPath 	= variables.Config.getLogPathExpanded();				// Get the root location for our logging.
		variables.paths.Exceptions 	= variables.Config.getPath('exceptions');				// Track the unique exceptions.
		variables.paths.Incidents 	= variables.Config.getPath('incidents');				// Track the hits per exception.
		variables.paths.Report 		= variables.Config.getPath('exceptionReport');			// The actual report
		variables.paths.Activity 	= variables.Config.getPath('exceptionReportActivity');	// Track when we save things. Helps understand volume.
		//variables.paths.Index 	= variables.Config.getPath('exceptionIndex');			// Tracks the exception keys to prevent duplication

		verifyDirectoryStructure();

		try {
		// For the life of this HothTracker, keep the ApplicationManager.
		variables.HothApplicationManager = new Hoth.object.HothApplicationManager(HothConfig);
		// Because the entire application db file is locked, we only want to
		// learn about this application when the HothTracker is created. The
		// actual amount of work done within the manager is small, but, it is
		// does block all other processes for all other Hoth instances, so, we
		// want to reduce calls to it to this constructor.
		variables.HothApplicationManager.learnApplication(arguments.HothConfig);
		} catch (any e) {
			//writeDump(e);abort;
		}
		return this;
	}

	/** Track an exception.
		@ExceptionStructure A ColdFusion cfcatch or a supported object from a Framework or Application. */
	public boolean function track (any Exception) {
		local.ExceptionStructure = parseException(arguments.Exception);

		// If we did not parse what we are supposed to
		// track, we will abort.
		if (!local.ExceptionStructure.validException)
			return false;

		// ------------------------------------------------------------------------------
		try {
		// ------------------------------------------------------------------------------
			local.e = {
				 detail 	= structKeyExists(local.ExceptionStructure,'detail') ? local.ExceptionStructure.detail : '_noDetail'
				,message 	= structKeyExists(local.ExceptionStructure,'message') ? local.ExceptionStructure.message : '_noMessage'
				,stack 		= structKeyExists(local.ExceptionStructure,'stacktrace') ? local.ExceptionStructure.stacktrace : '_no_stacktrace'
				,context 	= structKeyExists(local.ExceptionStructure,'tagcontext') ? local.ExceptionStructure.tagcontext : '_no_tagcontext'
				,format     = structKeyExists(local.ExceptionStructure,'format') ? local.ExceptionStructure.format: '_no_format'
				,url		= CGI.HTTP_HOST & CGI.path_info
				,client		= CGI.HTTP_USER_AGENT
			};

			// Generate JSON for hashing
			local.json = {};
			local.k = '';
			for(local.k in local.e)
				local.json[k] = serializeJSON(local.e[local.k]);

			// Hash a unique key for the content of each property within the exception
			local.index = {};
			local.index.stack = ( len(local.e.stack) > 0) ? hash(lcase(local.e.stack),'SHA') : '_no_stack';
			local.index.key = lcase(local.index.stack);

			local.saveDetails = false;

			// Index the exception, count occurances and save details.
			// Lock is unique to the exception.
			lock name=local.index.key timeout=variables.Config.getTimeToLock() type="exclusive" {
				local.filename = local.index.key & '.log';
				local.exceptionFile = variables.paths.Exceptions & '/' & local.filename;
				local.incidentsFile = variables.paths.Incidents & '/' & local.filename;

				local.exceptionIsKnown = fileExists(local.exceptionFile);

				if (!local.exceptionIsKnown)
					fileWrite(local.exceptionFile ,serializeJSON(local.e),'UTF-8');

				// Create an incident if the file does not exist
				if (!fileExists(local.incidentsFile)) {
					fileWrite(local.incidentsFile ,now() & '#chr(13)#','UTF-8');
				} else {
					local.file = fileOpen(local.incidentsFile,'append','utf-8');
					fileWriteLine(local.file, now() & '|' & local.e.url );
					fileClose(local.file);
				}
			}

			// Outside the lock, send mail if requested
			if (!local.exceptionIsKnown && variables.Config.getEmailNewExceptions() ) {

					local.INetAddress = createObject( 'java', 'java.net.InetAddress' );

					local.url = (len(CGI.QUERY_STRING) > 0)
						? CGI.http_host & CGI.path_info & '?' & Cgi.QUERY_STRING
						: CGI.http_host & CGI.path_info;

					local.emailBody = [
						 "Hoth tracked a new exception (" & local.index.key & ")."
						,"Message: " & local.e.message
						,"Machine Name: " & local.INetAddress.getLocalHost().getHostName()
						,"Address: " & local.url
					];

					local.Mail = new Mail(	 subject='Hoth Exception (' & variables.Config.getApplicationName() & ') ' & local.index.key
											,to=variables.Config.getEmailNewExceptionsTo()
											,from=variables.Config.getEmailNewExceptionsFrom());

					// Attach the file
					if ( variables.Config.getEmailNewExceptionsFile() ) {
						local.Mail.addParam(file=local.exceptionFile);
						ArrayAppend( local.emailBody, "To view the attached exception info, copy and paste into FireBug's console (x = exception) and press CRTL+Enter." );
					}
					
					// Show exception as HTML inline?
					if ( variables.Config.getEmailExceptionsAsHTML() ) {
						local.Mail.setType( "html" );
						savecontent variable="local.emailBody" {
							writeOutput( arrayToList( local.emailBody, "<br />" ) );
							writeOutput( "<br />Exception Details:<br />");
							writeDump( local.e );
						}
						local.Mail.setBody( local.emailBody );
					}
					else {
						local.Mail.setBody( arrayToList( local.emailBody, "#chr(10)##chr(13)#" ) );
					}
					
					local.mail.Send();
			}
		// ------------------------------------------------------------------------------
		} catch (any e) {
			return false;
		}
		// ------------------------------------------------------------------------------
		return true;
	}

	// Private Methods Follow -------------------------------------------------------
	/** Parse an exception provided by a framework or supported application.
		Hoth is easy to support. Just provide a Struct with at least the following keys:
			'detail,type,tagContext,StackTrace,Message'
		Or an object with the same information that Hoth can extract. */
	private struct function parseException(any Exception) {
		local.result = { validException = false };

		// Return the meta data for our passed exception
		local.md = getMetaData(Exception);

		// Inspect the class tree to understand what type of object
		// we are working with.
		local.classTree = GetClassHeirarchy(local.md);

		// Was our object built with ColdFusion? If so, it is custom.
		// If not, the object is considered to be native and generated by CF.
		local.exceptionType = (
			listContainsNoCase(local.classTree, 'coldfusion.runtime.AttributeCollection', ' ')
		) ? 'Custom' : 'Native';

		if (local.exceptionType == 'Native')
		{
			local.result.detail 		= (structKeyExists(arguments.Exception, 'detail')) ? arguments.Exception.detail : 'undefined';
			local.result.message 		= (structKeyExists(arguments.Exception, 'message')) ? arguments.Exception.message : 'undefined';
			local.result.stacktrace 	= (structKeyExists(arguments.Exception, 'stacktrace')) ? arguments.Exception.stacktrace : 'undefined';
			local.result.tagcontext 	= (structKeyExists(arguments.Exception, 'tagContext')) ? arguments.Exception.tagContext : 'undefined';
			local.result.validException = true;
			local.result.format 		= 'Native';

			// ADDED by Benoit Hediard to get real detail and message in FW1
			if (local.result.message == "Event handler exception." && structKeyExists(arguments.Exception, "Cause")) {
				local.result.detail 	= (structKeyExists(arguments.Exception.Cause, 'detail')) ? arguments.Exception.Cause.detail : 'undefined';
				local.result.message 	= (structKeyExists(arguments.Exception.Cause, 'message')) ? arguments.Exception.Cause.message : 'undefined';
			};
			return local.result;
		} else {
			//detail,type,tagcontext,stacktrace,message
			switch(local.md.fullname) {
				// ColdBox Excepiont
				case 'coldbox.system.beans.ExceptionBean' :
				case 'coldbox.system.web.context.ExceptionBean' :
					local.result.detail 	= arguments.Exception.getDetail();
					local.result.message 	= arguments.Exception.getMessage();
					local.result.stacktrace = arguments.Exception.getStackTrace();
					local.result.tagcontext = arguments.Exception.getTagContext();
					local.result.validException = true;
					local.result.format 		= 'ColdBox';
				break;
				// Unknown Exception Passed
				default :
					local.result.validException = false;
					local.result.format 		= 'Unknown';
				break;
				/*case 'MachII.util.Exception' :
					local.result = arguments.Exception.getCaughtException();
					local.result.validException = true;
				break;*/
			}
		}

		return local.result;
	}

	/** Inspect the class heirarchy to return a string showing the class tree.
	Original code is borrowed from Dominic Watson at the following address.
	Rewritten for for CF9+/Railo features.
	http://fusion.dominicwatson.co.uk/2007/09/coldfusion-objects-are-java-objects.html **/
	private function GetClassHeirarchy(obj) {
		local.thisClass = obj.GetClass();
		local.sReturn = thisClass.GetName();

		do{
	  		local.thisClass = local.thisClass.GetSuperClass();
	  		local.sReturn &= " " & thisClass.GetName();
		} while(CompareNoCase(thisClass.GetName(), 'java.lang.Object'));

		return local.sReturn;
	}

	/** Verify the desired directory structure exsits. */
	private void function verifyDirectoryStructure() {
		// Verify our index diectory exists

		/* Ensure our directory structure is as expected. */
		lock name=VARIABLES._NAME timeout=variables.Config.getTimeToLock() type="exclusive" {
			if (!directoryExists(variables.paths.Exceptions)) {
				directoryCreate(variables.paths.Exceptions);
				fileWrite(variables.paths.Exceptions & '/_readme.txt','Hoth: The files within this directory contain the complete details for each unique exception.');
			}
			if (!directoryExists(variables.paths.Incidents)) {
				directoryCreate(variables.paths.Incidents);
				fileWrite(variables.paths.Incidents & '/_readme.txt','Hoth: The files within this directory contain the details about the volume of errors for each unique exception.');
			}
		}

		return;
	}
}
