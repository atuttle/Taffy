component
    implements  = 'Hoth.object.iHothConfig'
    extends     = 'Hoth.object.CoreConfig'
    accessors   = 'true'
{

    /** What is the name of your application? */
    property
        name='applicationName'
        default='Taffy Tests';

    /** How many seconds should we lock file operations?
        For most operations this is exclusive to a unique exception. */
    property
        name='timeToLock'
        default='4';

    /** Where would you like Hoth to save exception data?
        This folder should be empty. */
    property
        name='logPath'
        default='/taffy/examples/api_hoth/hoth/exceptions';

    // ------------------------------------------------------------------------------
    /** Would you like new exceptions to be emailed to you? */
    property
        name='EmailNewExceptions'
        default='true';

    /** What address(es) should receive these e-mails? */
    property
        name='EmailNewExceptionsTo'
        default='you@yourdomain.com';

    /** What address would you like these emails sent from? */
    property
        name='EmailNewExceptionsFrom'
        default='hoth-error-report@yourdomain.com';

    /** Would you like the raw JSON attached to the e-mail? */
    property
        name='EmailNewExceptionsFile'
        default='true';
    // ------------------------------------------------------------------------------

    /**
    The mapping where you would like Hoth to write it's log files.
    Without this setting, Hoth will write log files to the same directory
    Hoth is located within. This is not recomended as your will have content
    mixed into your Hoth code.
    **/
    setGlobalDatabasePath(path='/taffy/examples/api_hoth/hoth/logs/');

    //make the log path be evaluated as relative
    variables.logPathIsRelative = true;

}
