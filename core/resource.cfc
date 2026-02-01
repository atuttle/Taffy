component hint="base class for taffy REST components" {

	public function forceString(required data) hint="the data that is being forced to serialize as a string" {
		return chr(2) & arguments.data;
	}

	variables.encode = {};
	variables.encode.string = forceString;

	public function representationOf(required data) output="false" hint="returns an object capable of serializing the data in a variety of formats" {
		return getRepInstance().setData(arguments.data);
	}

	public function rep(required data) output="false" hint="alias for representationOf" {
		return representationOf(arguments.data);
	}

	private function noData() output="false" hint="use this function to return only headers to the consumer, no data" {
		return getRepInstance().noData();
	}

	private function noContent() output="false" hint="use this function to return only headers to the consumer, no data" {
		return getRepInstance().noContent();
	}

	private function streamFile(required fileName) output="false" hint="Use this function to specify a file name (eg c:\tmp\kitten.jpg) to be streamed to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type." {
		return getRepInstance().setFileName(arguments.fileName);
	}

	private function streamBinary(required binaryData) output="false" hint="Use this function to stream binary data, like a generated PDF object, to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type." {
		return getRepInstance().setFileData(arguments.binaryData);
	}

	private function streamImage(required binaryData) output="false" hint="Use this function to stream binary data, like a generated PDF object, to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type." {
		return getRepInstance().setImageData(arguments.binaryData);
	}

	public function saveLog(exception) {
		var logger = createObject("component", application._taffy.settings.exceptionLogAdapter).init(
			application._taffy.settings.exceptionLogAdapterConfig
		);
		logger.saveLog(exception);
	}

	private array function qToArray(required query q, cb) output="false" {
		var local = {};
		if (structKeyExists(server, "railo") or structKeyExists(server, "lucee")) {
			local.Columns = listToArray(arguments.q.getColumnList(false));
		} else {
			local.Columns = arguments.q.getMetaData().getColumnLabels();
		}
		local.QueryArray = [];
		for (local.RowIndex = 1; local.RowIndex <= arguments.q.RecordCount; local.RowIndex++) {
			local.Row = {};
			local.numCols = arrayLen(local.Columns);
			for (local.ColumnIndex = 1; local.ColumnIndex <= local.numCols; local.ColumnIndex++) {
				local.ColumnName = local.Columns[local.ColumnIndex];
				if (local.ColumnName != "") {
					local.Row[local.ColumnName] = arguments.q[local.ColumnName][local.RowIndex];
				}
			}
			if (structKeyExists(arguments, "cb")) {
				local.Row = cb(local.Row);
			}
			arrayAppend(local.QueryArray, local.Row);
		}
		return local.QueryArray;
	}

	if (application._taffy.compat.queryToArray eq "missing") {
		private struct function queryToArray(required query q, cb) output="false" {
			return qToArray(arguments.q, arguments.cb);
		}
	}

	private struct function qToStruct(required query q, cb) output="false" {
		var local = {};

		if (q.recordcount gt 1) {
			throw(message="Unable to convert query resultset with more than one record to a simple struct, use queryToArray() instead");
		}

		if (structKeyExists(server, "railo") or structKeyExists(server, "lucee")) {
			local.Columns = listToArray(arguments.q.getColumnList(false));
		} else {
			local.Columns = arguments.q.getMetaData().getColumnLabels();
		}

		local.QueryStruct = {};
		local.numCols = arrayLen(local.Columns);

		for (local.ColumnIndex = 1; local.ColumnIndex <= local.numCols; local.ColumnIndex++) {
			local.ColumnName = local.Columns[local.ColumnIndex];
			if (local.ColumnName != "") {
				if (structKeyExists(arguments, "cb")) {
					local.QueryStruct[local.ColumnName] = cb(local.ColumnName, arguments.q[local.ColumnName][1]);
				} else {
					local.QueryStruct[local.ColumnName] = arguments.q[local.ColumnName][1];
				}
			}
		}

		return local.QueryStruct;
	}

	if (application._taffy.compat.queryToStruct eq "missing") {
		private struct function queryToStruct(required query q, cb) output="false" {
			return qToStruct(arguments.q, arguments.cb);
		}
	}

	/**
	 * function that gets the representation class instance
	 * -- if the argument is blank, we use the default from taffy settings
	 * -- if the argument is a beanName, the bean is returned from the factory;
	 * -- otherwise it is assumed to be a cfc path and that cfc instance is returned
	 */
	private function getRepInstance(string repClass="") output="false" {
		if (repClass eq "") {
			// recursion not the most efficient path here, but it's damn readable
			return getRepInstance(application._taffy.settings.serializer);
		} else if (application._taffy.factory.containsBean(arguments.repClass)) {
			return application._taffy.factory.getBean(arguments.repClass);
		} else {
			return createObject("component", arguments.repClass);
		}
	}

	package function addDebugData(data) output="false" {
		request.debugData = arguments.data;
	}

}
