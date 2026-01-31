/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 10/01/2010

	Core configuration object for Hoth. This object provides all the
	functionality for a Hoth Config Object. Individual implementations should
	extend this object and provide their own values within the property
	declaration.

	// -------------------------------------------------------------------------
	Modified		: 	12/13/2010 10:04:06 AM by Aaron Greenlee.
					-	Added support for global settings.

*/
component
accessors='true'
{

	/** Construct a configuration object for Hoth. */
	public function init ()
	{
		local.md = getMetadata(this);
		local.n = arrayLen(local.md.properties);
		for (local.i=1; local.i <= local.n; local.i++) {
			local.fn = this['set' & local.md.properties[local.i].name];
			local.fn(local.md.properties[local.i]['default']);
		}
		return this;
	}

	public void function setGlobalDatabasePath(required string path) {
		variables.GlobalDatabasePath = arguments.path;
	}
	public string function getGlobalDatabasePath() {
		return (structKeyExists(variables, 'GlobalDatabasePath'))
		? variables.GlobalDatabasePath
		: '/Hoth/db/';
	}

	/** Expands a path **/
	public string function getLogPathExpanded ()
	{
		if (!structKeyExists(variables, 'logPathIsRelative')) {
			variables.logPathIsRelative = false;
		}
		return variables.logPathIsRelative ? expandPath( getLogPath() ) : getLogPath();
	}

	/** Return a path for Hoth. */
	public string function getPath (name)
	{
		switch (arguments.name) {
			// Sub-Directories
			case 'incidents' :
			case 'exceptions' :
				return getLogPathExpanded() & '/' & lcase(arguments.name);
			break;

			// Files
			case 'exceptionIndex' :
			case 'exceptionReport' :
			case 'exceptionReportActivity' :
				return getLogPathExpanded() & '/' & lcase(arguments.name) & '.log';
			break;
		}
	}
}