component extends="taffy.core.baseSerializer" {

	public function getAsXML() output="false" taffy_mime="application/xml" taffy_default="true" {
		return application.anythingToXml.toXml(variables.data);
	}

}
