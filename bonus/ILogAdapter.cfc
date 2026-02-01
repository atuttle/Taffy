interface {

	public function init(config, tracker) hint="I accept a configuration structure to setup and return myself";
	public function saveLog(exception) hint="I log or otherwise notify you of an exception";

}
