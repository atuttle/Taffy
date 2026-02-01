component implements="taffy.bonus.ILogAdapter" {

	public function init(config, tracker="") hint="unused tracker" {
		variables.config = {};
		structAppend(variables.config, arguments.config, true);
		return this;
	}

	public function saveLog(exception) {
		var local = {};

		variables.config = removeEmailPrefix(variables.config);

		// to conform to the cfmail attribute name and be backward compatible with emailSubj
		variables.config.subject = variables.config.subj;

		local.attributeCollection = variables.config;

		cfmail(attributeCollection=local.attributeCollection) {
			if (variables.config.type eq "text") {
				writeOutput("Exception Report

Exception Timestamp: #dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#

");
				writeDump(var=arguments.exception, format="text");
				if (isDefined('request.debugData')) {
					writeDump(var=request.debugData, label="debug data", format="text");
				}
			} else {
				writeOutput("<h2>Exception Report</h2>
<p><strong>Exception Timestamp:</strong> #dateformat(now(), 'yyyy-mm-dd')# #timeformat(now(), 'HH:MM:SS tt')#</p>");
				writeDump(arguments.exception);
				if (isDefined('request.debugData')) {
					writeDump(var=request.debugData, label="debug data");
				}
			}
		}
	}

	private struct function removeEmailPrefix(required struct configAttributes) output="false" hint="removes all email prefix from the config attributes" {
		var configAttributeName = "";
		var configAttributeValue = "";
		var newConfig = {};
		var configAttributeNameWithoutEmailPrefix = "";
		for (configAttributeName in arguments.configAttributes) {
			configAttributeNameWithoutEmailPrefix = replaceNoCase(configAttributeName, "email", "", "one");
			newConfig[configAttributeNameWithoutEmailPrefix] = arguments.configAttributes[configAttributeName];
		}
		return newConfig;
	}

}
