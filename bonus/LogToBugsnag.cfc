/**
 * Adapter Path: taffy.bonus.LogToBugsnag
 * Configuration Options: (structure)
 *
 * variables.framework.exceptionLogAdapterConfig = {
 *     apiKey = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8",
 *     appVersion = "1.1.3",
 *     releaseStage = "production"
 * };
 *
 * apiKey: The API Key associated with the project
 * appVersion: The version number of the application which generated the error
 * releaseStage: The release stage that this error occurred in (e.g "development", "staging" or "production")
 */
component implements="taffy.bonus.ILogAdapter" {

	/**
	 * Initializes this logger
	 */
	public function init(config, tracker) hint="I accept a configuration structure to setup and return myself" {
		variables.config = {};
		structAppend(variables.config, arguments.config, true);
		return this;
	}

	/**
	 * Logs or notifies the specified exception
	 */
	public function saveLog(exception) hint="I log or otherwise notify you of an exception" {
		var payload = {};

		// Add Project API key to payload
		payload["apiKey"] = variables.config.apiKey;

		// Add notifier info to payload
		payload["notifier"] = {};
		payload["notifier"]["name"] = "Taffy";
		payload["notifier"]["version"] = "1.0";
		payload["notifier"]["url"] = "https://github.com/atuttle/Taffy";

		// Add exception details to payload
		payload["events"] = [];
		payload["events"][1] = {};
		payload["events"][1]["payloadVersion"] = "2";
		payload["events"][1]["exceptions"] = [];
		payload["events"][1]["exceptions"][1] = convertException(arguments.exception);

		// Add application details to payload
		payload["events"][1]["app"] = {};
		payload["events"][1]["app"]["appVersion"] = variables.config.appVersion;
		payload["events"][1]["app"]["releaseStage"] = variables.config.releaseStage;

		// Add some metadata to payload
		payload["events"][1]["metaData"] = {};
		payload["events"][1]["metaData"]["request"] = {};
		payload["events"][1]["metaData"]["request"]["remoteAddr"] = cgi.remote_addr;
		payload["events"][1]["metaData"]["request"]["requestMethod"] = cgi.request_method;
		payload["events"][1]["metaData"]["request"]["requestUrl"] = cgi.request_url;

		// Send log to Bugsnag
		cfhttp(url="https://notify.bugsnag.com", method="post") {
			cfhttpparam(type="header", name="Content-Type", value="application/json");
			cfhttpparam(type="body", value=serializeJSON(payload));
		}
	}

	/**
	 * Converts the specified exception to be added to the payload
	 */
	private struct function convertException(required struct exception) output="false" {
		var root = "";
		var exceptionElement = {};
		var tagContextElement = "";

		// Get the root exception
		if (structKeyExists(exception, "rootCause")) {
			root = arguments.exception.rootCause;
		} else {
			root = arguments.exception;
		}

		// Add type and message to payload
		exceptionElement["errorClass"] = root.type;
		exceptionElement["message"] = root.message;

		// Build stack trace
		exceptionElement["stacktrace"] = [];
		for (tagContextElement in root.TagContext) {
			arrayAppend(exceptionElement["stacktrace"], convertTagContextElement(tagContextElement));
		}

		return exceptionElement;
	}

	/**
	 * Converts the specified Tag Context element to be included in the stack trace array
	 */
	private struct function convertTagContextElement(required struct tagContextElement) output="false" {
		var stackTraceElement = {};

		// Add stack trace data
		stackTraceElement["file"] = arguments.tagContextElement.template;
		stackTraceElement["lineNumber"] = arguments.tagContextElement.line;
		stackTraceElement["columnNumber"] = arguments.tagContextElement.column;
		stackTraceElement["method"] = "Unknown function";

		// Add code details
		if (structKeyExists(arguments.tagContextElement, "codePrintPlain")) {
			stackTraceElement["code"] = convertCodePrint(arguments.tagContextElement.codePrintPlain);
		}

		return stackTraceElement;
	}

	/**
	 * Converts the specified code details to be included to the stack trace element
	 */
	private struct function convertCodePrint(required string codePrintText) output="false" {
		var codeLines = {};
		var split = listToArray(arguments.codePrintText, chr(10));
		var line = "";

		// Add code lines
		for (line in split) {
			structInsert(codeLines, listFirst(line, ":"), trim(listRest(line, ":")));
		}

		return codeLines;
	}

}
