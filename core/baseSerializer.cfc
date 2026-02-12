component output="false" hint="a helper class to represent easily serializable data" {

	variables.data = "";
	variables.fileName = "";
	variables.fileMime = "";
	variables.statusCode = 200;
	variables.statusText = "OK";
	variables.miscHeaders = {};
	variables.deleteFile = false;
	variables.noDataSends204NoContent = false;
	// 1= textual, 2= filename, 3= file data
	variables.type = 1;
	variables.types = {};
	variables.types[1] = "textual";
	variables.types[2] = "filename";
	variables.types[3] = "filedata";
	variables.types[4] = "imagedata";
	variables.statusTexts = {};
	variables.statusTexts[100] = "Continue";
	variables.statusTexts[101] = "Switching Protocols";
	variables.statusTexts[102] = "Processing";
	variables.statusTexts[200] = "OK";
	variables.statusTexts[201] = "Created";
	variables.statusTexts[202] = "Accepted";
	variables.statusTexts[203] = "Non-authoritative Information";
	variables.statusTexts[204] = "No Content";
	variables.statusTexts[205] = "Reset Content";
	variables.statusTexts[206] = "Partial Content";
	variables.statusTexts[207] = "Multi-Status";
	variables.statusTexts[208] = "Already Reported";
	variables.statusTexts[226] = "IM Used";
	variables.statusTexts[300] = "Multiple Choices";
	variables.statusTexts[301] = "Moved Permanently";
	variables.statusTexts[302] = "Found";
	variables.statusTexts[303] = "See Other";
	variables.statusTexts[304] = "Not Modified";
	variables.statusTexts[305] = "Use Proxy";
	variables.statusTexts[307] = "Temporary Redirect";
	variables.statusTexts[308] = "Permanent Redirect";
	variables.statusTexts[400] = "Bad Request";
	variables.statusTexts[401] = "Unauthorized";
	variables.statusTexts[402] = "Payment Required";
	variables.statusTexts[403] = "Forbidden";
	variables.statusTexts[404] = "Not Found";
	variables.statusTexts[405] = "Method Not Allowed";
	variables.statusTexts[406] = "Not Acceptable";
	variables.statusTexts[407] = "Proxy Authentication Required";
	variables.statusTexts[408] = "Request Timeout";
	variables.statusTexts[409] = "Conflict";
	variables.statusTexts[410] = "Gone";
	variables.statusTexts[411] = "Length Required";
	variables.statusTexts[412] = "Precondition Failed";
	variables.statusTexts[413] = "Payload Too Large";
	variables.statusTexts[414] = "Request-URI Too Long";
	variables.statusTexts[415] = "Unsupported Media Type";
	variables.statusTexts[416] = "Requested Range Not Satisfiable";
	variables.statusTexts[417] = "Expectation Failed";
	variables.statusTexts[418] = "I'm a teapot";
	variables.statusTexts[421] = "Misdirected Request";
	variables.statusTexts[422] = "Unprocessable Entity";
	variables.statusTexts[423] = "Locked";
	variables.statusTexts[424] = "Failed Dependency";
	variables.statusTexts[426] = "Upgrade Required";
	variables.statusTexts[428] = "Precondition Required";
	variables.statusTexts[429] = "Too Many Requests";
	variables.statusTexts[431] = "Request Header Fields Too Large";
	variables.statusTexts[444] = "Connection Closed Without Response";
	variables.statusTexts[451] = "Unavailable For Legal Reasons";
	variables.statusTexts[499] = "Client Closed Request";
	variables.statusTexts[500] = "Internal Server Error";
	variables.statusTexts[501] = "Not Implemented";
	variables.statusTexts[502] = "Bad Gateway";
	variables.statusTexts[503] = "Service Unavailable";
	variables.statusTexts[504] = "Gateway Timeout";
	variables.statusTexts[505] = "HTTP Version Not Supported";
	variables.statusTexts[506] = "Variant Also Negotiates";
	variables.statusTexts[507] = "Insufficient Storage";
	variables.statusTexts[508] = "Loop Detected";
	variables.statusTexts[510] = "Not Extended";
	variables.statusTexts[511] = "Network Authentication Required";
	variables.statusTexts[599] = "Network Connect Timeout Error";

	public function getType() output="false" {
		return variables.types[variables.type];
	}

	public function setData(required data) output="false" hint="setter for the data to be returned" {
		variables.type = 1;
		variables.data = arguments.data;
		return this;
	}

	public function getData() output="false" hint="mostly for testability, returns the native data embedded in the representation instance" {
		return variables.data;
	}

	public function setNoDataSends204NoContent(required boolean value) output="false" {
		variables.noDataSends204NoContent = arguments.value;
		return this;
	}

	public function noData() output="false" hint="returns empty representation instance" {
		if (variables.noDataSends204NoContent) {
			return this.noContent();
		} else {
			return this;
		}
	}

	public function noContent() output="false" hint="returns empty representation instance" {
		// According to issue #365 https://github.com/atuttle/Taffy/issues/365
		// noContent() returns with HTTP status code 204 and Content-Type as text/plain (omitting this header is difficult and maybe not recommanded)
		// noData() is kept 'as is' for backward compatibility with existing implementations
		return this.withStatus(204).withHeaders({"Content-Type"="text/plain"});
	}

	public function setFileName(required string file) output="false" hint="Pass in a file-name (fully qualified, e.g. c:\temp\img.jpg) to have Taffy stream this file back to the client" {
		variables.type = 2;
		variables.fileName = arguments.file;
		return this;
	}

	public function getFileName() output="false" {
		return variables.fileName;
	}

	public function setFileData(required data) output="false" hint="Pass in file data (eg a generated PDF object) - NOT a Filename! - to have Taffy stream the content back to the client" {
		variables.type = 3;
		variables.fileData = arguments.data;
		return this;
	}

	public function getFileData() output="false" {
		return variables.fileData;
	}

	public function setImageData(required data) output="false" hint="Pass in image data (eg a generated image object) - NOT a Filename! - to have Taffy stream the content back to the client" {
		variables.type = 4;
		if (!isBinary(arguments.data)) {
			arguments.data = toBinary(toBase64(arguments.data));
		}
		variables.fileData = arguments.data;
		return this;
	}

	public function getImageData() output="false" {
		return getFileData();
	}

	public function withMime(required string mime) output="false" hint="Use this method in conjunction with streamFile and streamBinary in your resources to set the mime type of the file being returned. Ex: return streamFile('kittens/cuteness.jpg').withMime('image/jpeg');" {
		variables.fileMime = arguments.mime;
		return this;
	}

	public function getFileMime() output="false" {
		return variables.fileMime;
	}

	public function withStatus(required numeric statusCode, string statusText="") output="false" hint="used to set the http response code for the response" {
		variables.statusCode = arguments.statusCode;
		if (len(arguments.statusText)) {
			variables.statusText = arguments.statusText;
		} else if (structKeyExists(variables.statusTexts, arguments.statusCode)) {
			variables.statusText = variables.statusTexts[arguments.statusCode];
		}
		return this;
	}

	public numeric function getStatus() output="false" {
		return variables.statusCode;
	}

	public string function getStatusText() output="false" {
		return variables.statusText;
	}

	public function withHeaders(required struct headerStruct) output="false" hint="used to set custom headers for the response" {
		variables.miscHeaders = arguments.headerStruct;
		return this;
	}

	public struct function getHeaders() output="false" {
		return variables.miscHeaders;
	}

	public function andDelete(required boolean doDeleteFile) output="false" hint="used to delete the streamed file" {
		variables.deleteFile = arguments.doDeleteFile;
		return this;
	}

	public boolean function getDeleteFile() output="false" {
		return variables.deleteFile;
	}

}
