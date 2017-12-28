<cfcomponent output="false" hint="a helper class to represent easily serializable data">

	<cfset variables.data = "" />
	<cfset variables.fileName = "" />
	<cfset variables.fileMime = "" />
	<cfset variables.statusCode = 200 />
	<cfset variables.statusText = "OK" />
	<cfset variables.miscHeaders = StructNew() />
	<cfset variables.deleteFile = false />
	<!--- 1= textual, 2= filename, 3= file data --->
	<cfset variables.type = 1 />
	<cfset variables.types = StructNew() />
	<cfset variables.types[1] = "textual" />
	<cfset variables.types[2] = "filename" />
	<cfset variables.types[3] = "filedata" />
	<cfset variables.types[4] = "imagedata" />
	<cfset variables.statusTexts = StructNew() />
	<cfset variables.statusTexts[100] = "Continue" />
	<cfset variables.statusTexts[101] = "Switching Protocols" />
	<cfset variables.statusTexts[102] = "Processing" />
	<cfset variables.statusTexts[200] = "OK" />
	<cfset variables.statusTexts[201] = "Created" />
	<cfset variables.statusTexts[202] = "Accepted" />
	<cfset variables.statusTexts[203] = "Non-authoritative Information" />
	<cfset variables.statusTexts[204] = "No Content" />
	<cfset variables.statusTexts[205] = "Reset Content" />
	<cfset variables.statusTexts[206] = "Partial Content" />
	<cfset variables.statusTexts[207] = "Multi-Status" />
	<cfset variables.statusTexts[208] = "Already Reported" />
	<cfset variables.statusTexts[226] = "IM Used" />
	<cfset variables.statusTexts[300] = "Multiple Choices" />
	<cfset variables.statusTexts[301] = "Moved Permanently" />
	<cfset variables.statusTexts[302] = "Found" />
	<cfset variables.statusTexts[303] = "See Other" />
	<cfset variables.statusTexts[304] = "Not Modified" />
	<cfset variables.statusTexts[305] = "Use Proxy" />
	<cfset variables.statusTexts[307] = "Temporary Redirect" />
	<cfset variables.statusTexts[308] = "Permanent Redirect" />
	<cfset variables.statusTexts[400] = "Bad Request" />
	<cfset variables.statusTexts[401] = "Unauthorized" />
	<cfset variables.statusTexts[402] = "Payment Required" />
	<cfset variables.statusTexts[403] = "Forbidden" />
	<cfset variables.statusTexts[404] = "Not Found" />
	<cfset variables.statusTexts[405] = "Method Not Allowed" />
	<cfset variables.statusTexts[406] = "Not Acceptable" />
	<cfset variables.statusTexts[407] = "Proxy Authentication Required" />
	<cfset variables.statusTexts[408] = "Request Timeout" />
	<cfset variables.statusTexts[409] = "Conflict" />
	<cfset variables.statusTexts[410] = "Gone" />
	<cfset variables.statusTexts[411] = "Length Required" />
	<cfset variables.statusTexts[412] = "Precondition Failed" />
	<cfset variables.statusTexts[413] = "Payload Too Large" />
	<cfset variables.statusTexts[414] = "Request-URI Too Long" />
	<cfset variables.statusTexts[415] = "Unsupported Media Type" />
	<cfset variables.statusTexts[416] = "Requested Range Not Satisfiable" />
	<cfset variables.statusTexts[417] = "Expectation Failed" />
	<cfset variables.statusTexts[418] = "I'm a teapot" />
	<cfset variables.statusTexts[421] = "Misdirected Request" />
	<cfset variables.statusTexts[422] = "Unprocessable Entity" />
	<cfset variables.statusTexts[423] = "Locked" />
	<cfset variables.statusTexts[424] = "Failed Dependency" />
	<cfset variables.statusTexts[426] = "Upgrade Required" />
	<cfset variables.statusTexts[428] = "Precondition Required" />
	<cfset variables.statusTexts[429] = "Too Many Requests" />
	<cfset variables.statusTexts[431] = "Request Header Fields Too Large" />
	<cfset variables.statusTexts[444] = "Connection Closed Without Response" />
	<cfset variables.statusTexts[451] = "Unavailable For Legal Reasons" />
	<cfset variables.statusTexts[499] = "Client Closed Request" />
	<cfset variables.statusTexts[500] = "Internal Server Error" />
	<cfset variables.statusTexts[501] = "Not Implemented" />
	<cfset variables.statusTexts[502] = "Bad Gateway" />
	<cfset variables.statusTexts[503] = "Service Unavailable" />
	<cfset variables.statusTexts[504] = "Gateway Timeout" />
	<cfset variables.statusTexts[505] = "HTTP Version Not Supported" />
	<cfset variables.statusTexts[506] = "Variant Also Negotiates" />
	<cfset variables.statusTexts[507] = "Insufficient Storage" />
	<cfset variables.statusTexts[508] = "Loop Detected" />
	<cfset variables.statusTexts[510] = "Not Extended" />
	<cfset variables.statusTexts[511] = "Network Authentication Required" />
	<cfset variables.statusTexts[599] = "Network Connect Timeout Error" />

	<cffunction name="getType" acces="public" output="false">
		<cfreturn variables.types[variables.type] />
	</cffunction>

	<cffunction name="setData" access="public" output="false" hint="setter for the data to be returned">
		<cfargument name="data" required="true" hint="the simple or complex data that you want to return to the api consumer" />
		<cfset variables.type = 1 />
		<cfset variables.data = arguments.data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getData" access="public" output="false" hint="mostly for testability, returns the native data embedded in the representation instance">
		<cfreturn variables.data />
	</cffunction>

	<cffunction name="noData" access="public" output="false" hint="returns empty representation instance">
		<cfif application._taffy.settings.noDataSends204NoContent>
			<cfreturn this.noContent() />
		<cfelse>
			<cfreturn this />
		</cfif>
	</cffunction>

	<cffunction name="noContent" access="public" output="false" hint="returns empty representation instance">
		<!--- According to issue #365 https://github.com/atuttle/Taffy/issues/365
				noContent() returns with HTTP status code 204 and Content-Type as text/plain (omitting this header is difficult and maybe not recommanded)
				noData() is kept 'as is' for backward compatibility with existing implementations
		--->
		<cfreturn this.withStatus(204).withHeaders({"Content-Type":"text/plain"}) />
	</cffunction>

	<cffunction name="setFileName" access="public" output="false" hint="Pass in a file-name (fully qualified, e.g. c:\temp\img.jpg) to have Taffy stream this file back to the client">
		<cfargument name="file" type="string" required="true" />
		<cfset variables.type = 2 />
		<cfset variables.fileName = arguments.file />
		<cfreturn this />
	</cffunction>

	<cffunction name="getFileName" access="public" output="false">
		<cfreturn variables.fileName />
	</cffunction>

	<cffunction name="setFileData" access="public" output="false" hint="Pass in file data (eg a generated PDF object) - NOT a Filename! - to have Taffy stream the content back to the client">
		<cfargument name="data" required="true" />
		<cfset variables.type = 3 />
		<cfset variables.fileData = arguments.data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getFileData" access="public" output="false">
		<cfreturn variables.fileData />
	</cffunction>

	<cffunction name="setImageData" access="public" output="false" hint="Pass in image data (eg a generated image object) - NOT a Filename! - to have Taffy stream the content back to the client">
		<cfargument name="data" required="true" />
		<cfset variables.type = 4 />
		<cfif not isBinary(arguments.data)>
			<cfset arguments.data = toBinary(toBase64(arguments.data)) />
		</cfif>
		<cfset variables.fileData = arguments.data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getImageData" access="public" output="false">
		<cfreturn getFileData() />
	</cffunction>

	<cffunction name="withMime" access="public" output="false" hint="Use this method in conjunction with streamFile and streamBinary in your resources to set the mime type of the file being returned. Ex: return streamFile('kittens/cuteness.jpg').withMime('image/jpeg');">
		<cfargument name="mime" type="string" required="true" />
		<cfset variables.fileMime = arguments.mime />
		<cfreturn this />
	</cffunction>

	<cffunction name="getFileMime" access="public" output="false">
		<cfreturn variables.fileMime />
	</cffunction>

	<cffunction name="withStatus" access="public" output="false" hint="used to set the http response code for the response">
		<cfargument name="statusCode" type="numeric" required="true" hint="eg 200" />
		<cfargument name="statusText" type="string" required="false" default="" />
		<cfset variables.statusCode = arguments.statusCode />
		<cfif len(arguments.statusText)>
			<cfset variables.statusText = arguments.statusText />
		<cfelseif StructKeyExists(variables.statusTexts, arguments.statusCode)>
			<cfset variables.statusText = variables.statusTexts[arguments.statusCode] />
		</cfif>
		<cfreturn this />
	</cffunction>

	<cffunction name="getStatus" access="public" output="false" returnType="numeric">
		<cfreturn variables.statusCode />
	</cffunction>

	<cffunction name="getStatusText" access="public" output="false" returnType="string">
		<cfreturn variables.statusText />
	</cffunction>

	<cffunction name="withHeaders" access="public" output="false" hint="used to set custom headers for the response">
		<cfargument name="headerStruct" type="struct" required="true" />
		<cfset variables.miscHeaders = arguments.headerStruct />
		<cfreturn this />
	</cffunction>

	<cffunction name="getHeaders" access="public" output="false" returntype="Struct">
		<cfreturn variables.miscHeaders />
	</cffunction>

	<cffunction name="andDelete" access="public" output="false" hint="used to delete the streamed file">
		<cfargument name="doDeleteFile" type="boolean" required="true" />
		<cfset variables.deleteFile = arguments.doDeleteFile />
		<cfreturn this />
	</cffunction>

	<cffunction name="getDeleteFile" access="public" output="false" returntype="boolean">
		<cfreturn variables.deleteFile />
	</cffunction>

</cfcomponent>
