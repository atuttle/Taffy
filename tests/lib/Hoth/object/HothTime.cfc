component
{
	/**
	 * Returns the number of seconds since UTC January 1, 1970, 00:00:00
	 * (Epoch time).
	 *
	 * @param DateTime Date/time object you want converted to
	 * Epoch time.(Required)
	 *
	 * @return Returns a numeric value.
	 * @author Rob Brooks-Bilson (rbils@amkor.com)
	 * @version 1, June 21, 2002
	*/
	function GetEpochTimeFromLocal() {
		local.datetime = 0;

		if ( arrayLen(arguments) == 0)
		{
			local.datetime = Now();
		} else {
			local.datetime = arguments[1];
		}

		return
			DateDiff(
				"s"
				,DateConvert("utc2Local", "January 1 1970 00:00")
				,datetime);
	}
}