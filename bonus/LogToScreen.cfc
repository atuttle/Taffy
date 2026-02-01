component implements="taffy.bonus.ILogAdapter" {

	public function init(config, tracker="") hint="unused tracker" {
		return this;
	}

	public function saveLog(exception) {
		cfcontent(type="text/html");
		cfheader(statuscode="500", statustext="Unhandled API Error");
		writeDump(arguments);
		if (isDefined('request.debugData')) {
			writeDump(var=request.debugData, label="debug data");
		}
		abort;
	}

}
