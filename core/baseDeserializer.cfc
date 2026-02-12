component output="false" hint="a helper class to decode input data" {

	public function getFromForm(body) output="false" taffy_mime="application/x-www-form-urlencoded" hint="get data from form post" {
		var response = {};
		var pairs = listToArray(arguments.body, "&");
		var pair = "";
		var kv = [];
		var ix = 0;
		var k = "";
		var v = "";

		if (!find('=', arguments.body)) {
			throwError(400, "You've indicated that you're sending form-encoded data but it doesn't appear to be valid. Aborting request.");
		}

		for (ix = 1; ix <= arrayLen(pairs); ix++) {
			pair = pairs[ix];
			kv = listToArray(pair, "=", true);
			k = kv[1];
			v = urlDecode(kv[2]);
			if (structKeyExists(response, k)) {
				response[k] = listAppend(response[k], v);
			} else {
				response[k] = v;
			}
		}

		return response;
	}

	private void function throwError(numeric statusCode=500, required string msg, struct headers={}) output="false" {
		cfcontent(reset="true");
		addHeaders(arguments.headers);
		cfheader(statuscode=arguments.statusCode, statustext=arguments.msg);
		abort;
	}

	private void function addHeaders(required struct headers) output="false" {
		var h = '';
		if (!structIsEmpty(arguments.headers)) {
			for (h in arguments.headers) {
				cfheader(name=h, value=arguments.headers[h]);
			}
		}
	}

}
