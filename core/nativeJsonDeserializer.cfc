component extends="baseDeserializer" {

	public function getFromJson(body) output="false" taffy_mime="application/json,text/json" hint="get data from json" {
		var data = 0;
		var response = {};

		if (!isJson(arguments.body)) {
			throwError(msg="Input JSON is not well formed", statusCode="400");
		}
		data = deserializeJSON(arguments.body);
		if (!isStruct(data)) {
			response['_body'] = data;
		} else {
			response = data;
		}

		return response;
	}

}
