component extends="baseSerializer" output="false" hint="Serializer that uses CFML server's json serialization functionality to return json data" {

	public function getAsJson() output="false" taffy_mime="application/json;text/json" taffy_default="true" hint="serializes data as JSON" {
		return rereplace(replace(serializeJSON(variables.data), chr(2), '', 'ALL'), '"\\u0002', '"', 'ALL');
	}

}
