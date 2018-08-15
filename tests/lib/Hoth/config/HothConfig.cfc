/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 10/01/2010

	Default configuration for Hoth.

*/
component
	implements='Hoth.object.iHothConfig'
	extends='Hoth.object.CoreConfig'
	accessors=true {

	// -------------------------------------------------------------------------
	// BASIC HOTH SETTINGS (required)
	// -------------------------------------------------------------------------
	/** What is the name of your application? */
	property name='applicationName'			default='HothDefaultConfig';

	/** How many seconds should we lock file operations?
		For most operations this is exclusive to a unique exception. */
	property name='timeToLock' 				default='1';

	/** Where would you like Hoth to save exception data?
		This folder should be empty when you start. */
	property name='logPath' 				default='/Hoth/examples/Example_Logs';

	/** Is the log file location relative to the webroot?
		This folder should be empty when you start. */
	property name='logPathIsRelative' 		default='true';
	
	// -------------------------------------------------------------------------
	// HOTH EMAIL SETTINGS (required)
	// -------------------------------------------------------------------------
	/** Would you like new exceptions to be emailed to you? */
	property name='EmailNewExceptions' 		default='false';

	/** What address(es) should receive these e-mails? */
	property name='EmailNewExceptionsTo' 	default='you@yourdomain.com';

	/** What address would you like these emails sent from? */
	property name='EmailNewExceptionsFrom' 	default='hoth@yourdomain.com';

	/** Would you like the raw JSON attached to the e-mail? */
	property name='EmailNewExceptionsFile' 	default='false';
	
	/** Would you like HTML emails which contain the exception? */
	property name='EmailExceptionsAsHTML' 	default='false';

	// -------------------------------------------------------------------------
	// HOTH REPORT SETTINGS (required)
	// -------------------------------------------------------------------------

	/** How you access the Hoth reports is up to you. When the reports are
		generated Hoth needs to know how to build links so you can navigate
		the report and get information from the server.

		You are responsible for deciding how you wish to access reports. Once
		you have figured that out, please, write the full URL here.
	**/
	property
		name='HothReportURL'
		default='http://office/lib/Hoth/examples/ColdFusion/HothReportUI.cfc';

	// -------------------------------------------------------------------------
	// Constructor
	// -------------------------------------------------------------------------
	public function init()
	{
		super.init();
		return this;
	}
}