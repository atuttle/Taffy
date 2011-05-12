<cfcomponent output="false" hint="a helper class to represent easily serializable data">

	<cfset variables.data = "" />
	<cfset variables.fileName = "" />
	<cfset variables.fileMime = "" />
	<cfset variables.statusCode = 200 />
	<cfset variables.statusText = "OK" />
	<cfset variables.miscHeaders = StructNew() />
	<!--- 1= textual, 2= filename, 3= file data --->
	<cfset variables.type = 1 />
	<cfset variales.types = StructNew() />
	<cfset variables.types[1] = "textual" />
	<cfset variables.types[2] = "filename" />
	<cfset variables.types[3] = "filedata" />
	<cfset variables.types[4] = "imagedata" />

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
		<cfreturn this />
	</cffunction>

	<cffunction name="setFileName" access="public" output="false" hint="Pass in a file-name (fully qualified, e.g. c:\temp\img.jpg) to have Taffy stream this file back to the client">
		<cfargument name="file" type="string" required="true" />
		<cfset variables.type = 2 />
		<cfset variables.fileName = file />
		<cfreturn this />
	</cffunction>

	<cffunction name="getFileName" access="public" output="false">
		<cfreturn variables.fileName />
	</cffunction>

	<cffunction name="setFileData" access="public" output="false" hint="Pass in file data (eg a generated PDF object) - NOT a Filename! - to have Taffy stream the content back to the client">
		<cfargument name="data" required="true" />
		<cfset variables.type = 3 />
		<cfset variables.fileData = data />
		<cfreturn this />
	</cffunction>

	<cffunction name="getFileData" access="public" output="false">
		<cfreturn variables.fileData />
	</cffunction>

	<cffunction name="setImageData" access="public" output="false" hint="Pass in image data (eg a generated image object) - NOT a Filename! - to have Taffy stream the content back to the client">
		<cfargument name="data" required="true" />
		<cfset variables.type = 4 />
		<cfif not isBinary(arguments.data)>
			<cfset data = toBinary(toBase64(arguments.data)) />
		</cfif>
		<cfset variables.fileData = data />
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

</cfcomponent>