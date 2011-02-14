component extends="taffy.core.nativeJsonRepresentation" {

	function getAsJSON()
		output="false"
		taffy_mime="text/json"
		taffy_default="true"
		hint="serializes data as JSON"
	{
		return super.getAsJson();
	}

}