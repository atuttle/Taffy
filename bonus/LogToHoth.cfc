component implements="taffy.bonus.ILogAdapter" {

	public function init(config, tracker=createObject("component", "Hoth.HothTracker")) {
		variables.hothtracker = arguments.tracker;
		variables.hothtracker.init(
			createObject("component", arguments.config)
		);
		return this;
	}

	public function saveLog(exception) {
		var local = {};
		local.result = variables.HothTracker.track(arguments.exception);
		cfheader(name="X-HOTH-LOGGED-EXCEPTION", value=local.result);
	}

}
