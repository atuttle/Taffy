component implements="taffy.bonus.ILogAdapter" {

	public function init(config, tracker="") hint="unused tracker" {
		variables.config = {};
		structAppend(variables.config, arguments.config, true);
		return this;
	}

	public function saveLog(exception) {
		var logdump = "";
		savecontent variable="logdump" {
			writeDump(var=arguments.exception, format="text");
		}
		writeLog(file=variables.config.logfile, text=logdump, type="Error");
	}

}
