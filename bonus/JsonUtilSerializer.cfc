component extends="taffy.core.baseSerializer" {

	variables.jsonUtil = application.jsonUtil;

	public function getAsJson() output="false" taffy_mime="application/json" taffy_default="true" {
		return variables.jsonUtil.serialize(variables.data);
	}

}
