/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 12/13/2010

	Responsible for helping Hoth report for multiple applications.
*/
component
name = 'HothApplicationManager'
accessors = true
{
	property name='applications' type='array';

	// The filename that holds application knowledge.
	VARIABLES.APP_LOCK_KEY = 'HothApplicationDBFileLock';

	/** Constructor.
	* @HothConfig Requires a HothConfig Object.
	*/
	public Hoth.object.HothApplicationManager function init(
		required HothConfig
	){

		setApplications( loadApplicationsFromDisk(HothConfig) );

		return this;
	}

	/** To allow for easy reporting, Hoth needs to be able to track new
		applications (or really, new log paths). When a new instance of
		HothTracker is created, this method will be called. **/
	public boolean function learnApplication(
		required HothConfig
	){
		// Prevent any other threads from saving our new application
		lock
			name=VARIABLES.APP_LOCK_KEY
			timeout=arguments.HothConfig.getTimeToLock()
			type="exclusive"
		{
			local.knownApplications =
				loadApplicationsFromDisk(argumentCollection=arguments);

			for(local.index in local.knownApplications)
			{
				// Confirm our keys exist
				if (structKeyExists(local.index, 'logPath'))
				{
					// If we find the same logPath, we know about this
					// application and need to exit.
					if (local.index.logPath == arguments.HothConfig.getLogPath())
					{
						return false;
					}
				}
			}

			// We did not find out application path within the file.
			// Create the struct and append it to our array.
			local.applicationDataToSave =
			{
				 'applicationName' = arguments.HothConfig.getApplicationName()
				,'logPath' = arguments.HothConfig.getLogPath()
				,'created' = now()
			};
			arrayAppend(
				 local.knownApplications
				,local.applicationDataToSave
			);

			// Save the contents of the entire array, replacing the entire file
			local.path = arguments.HothConfig.getGlobalDatabasePath();
			fileWrite(
				 expandPath(arguments.HothConfig.getGlobalDatabasePath() & 'applications.hoth')
				,serializeJSON(local.knownApplications)
				,'UTF-8'
			);
		}

		return true;
	}

	/** Loads applications already observed by Hoth from disk.
	*	This process should be locked by the calling method.
	*	@HothConfig Requires a HothConfig Object. */
	private array function loadApplicationsFromDisk (
		required HothConfig
	){
		local.path = arguments.HothConfig.getGlobalDatabasePath();
		local.appfile = expandPath(arguments.HothConfig.getGlobalDatabasePath() & 'applications.hoth');

		// Return an empty array if the appFile does not exist.
		if (!fileExists( local.appfile ) )
		{
			return [];
		}

		local.applicationsFound = fileRead( local.appfile );

		// Delete the database if the file is invalid.
		if (!isJSON(local.applicationsFound))
		{
			fileDelete( local.appfile );
			return [];
		}

		// Convert the file to our desired structure
		local.parsedDB = deserializeJSON(local.applicationsFound);

		return local.parsedDB;
	}
}