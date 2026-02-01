component implements="taffy.bonus.ILogAdapter" {

	public function init(config, tracker) {
		if (structKeyExists(arguments, "tracker")) {
			// used to inject mocking object for testing
			variables.blhq = arguments.tracker;
		} else {
			var svc = "bugLog.client.bugLogService";
			if (structKeyExists(arguments.config, "service")) {
				svc = arguments.config.service;
			}

			variables.blhq = createObject("component", svc);
			variables.blhq.init(argumentCollection=arguments.config);
		}

		param name="arguments.config.message" default="Exception trapped in API";
		variables.message = arguments.config.message;

		return this;
	}

	public function saveLog(exception) {
		var msg = '';

		if (structKeyExists(exception, 'rootcause') && structKeyExists(exception.rootcause, 'cause') && structKeyExists(exception.rootcause.cause, 'message')) {
			msg = exception.rootcause.cause.message;
		} else if (structKeyExists(exception, 'cause') && structKeyExists(exception.cause, 'message')) {
			msg = exception.cause.message;
		} else if (structKeyExists(exception, 'message')) {
			msg = exception.message;
		} else {
			msg = variables.message;
		}

		// You can use addDebugData() in resources to set this value
		if (structKeyExists(request, "debugData") and !structKeyExists(exception, "extraInfo")) {
			exception.extraInfo = request.debugData;
		}

		var reqHeaders = getHTTPRequestData().headers;
		var reqBody = getHTTPRequestData().content;
		// on input with content-type "application/json" CF seems to expose it as binary data. Here we convert it back to plain text
		if (isBinary(reqBody)) {
			reqBody = charsetEncode(reqBody, "UTF-8");
		}
		if (isJson(reqBody)) {
			reqBody = deserializeJson(reqBody);
		}

		variables.blhq.notifyService(msg, arguments.exception, { request_body: reqBody, request_headers: reqHeaders });
	}

}
