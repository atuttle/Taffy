// This CFC offers no protection--thus, anyone can access this.
// You can implement this by renaming the CFC with a UUID--that can secure
// this through obscurity. But, I prefer the approach shown in the ColdBox
// example. That is what I use. I have not tried this code :(

component 
{
	/** Loads the Web UI (HTML) **/
	remote function index () returnformat='plain' {
		local.HothReport = new Hoth.HothReporter( new config.HothConfig() );
		return local.HothReport.getReportView();
	}

	/** Access Hoth report data as JSON.
		@exception 	If not provided a list of exceptions will be returned.
					If provided, the value should be an exception hash which
					modified the behavior to return information for only
					that exception. **/
	remote function report (string exception) returnformat='JSON' {
		local.report = (structKeyExists(arguments, 'exception')
		? arguments.exception
		: 'all');

		local.HothReport = new Hoth.HothReporter( new config.HothConfig() );
		return local.HothReport.report(local.report);
	}

	/** Delete a report. **/
	remote function delete (string exception)returnformat='JSON'  {
		if (!structKeyExists(arguments, 'exception'))
		{
			// We can delete all exceptions at once!
			arguments.exception = 'all';
		}

		local.HothReport = new Hoth.HothReporter( new config.HothConfig() );

		// Delete!
		return local.HothReporter.delete(arguments.exception);
	}
}