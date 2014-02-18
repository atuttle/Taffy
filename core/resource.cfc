<cfcomponent hint="base class for taffy REST components">

	<!--- helper functions --->
	<cffunction name="representationOf" access="public" output="false" hint="returns an object capable of serializing the data in a variety of formats">
		<cfargument name="data" required="true" hint="any simple or complex data that should be returned for the request" />
		<cfreturn getRepInstance().setData(arguments.data) />
	</cffunction>

	<cffunction name="noData" access="private" output="false" hint="use this function to return only headers to the consumer, no data">
		<cfreturn getRepInstance().noData() />
	</cffunction>

	<cffunction name="streamFile" access="private" output="false" hint="Use this function to specify a file name (eg c:\tmp\kitten.jpg) to be streamed to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type.">
		<cfargument name="fileName" required="true" hint="fully qualified file path (eg c:\tmp\kitten.jpg)" />
		<cfreturn getRepInstance().setFileName(arguments.fileName) />
	</cffunction>

	<cffunction name="streamBinary" access="private" output="false" hint="Use this function to stream binary data, like a generated PDF object, to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type.">
		<cfargument name="binaryData" required="true" hint="binary file data (eg a PDF object) that you want to return to the client" />
		<cfreturn getRepInstance().setFileData(arguments.binaryData) />
	</cffunction>

	<cffunction name="streamImage" access="private" output="false" hint="Use this function to stream binary data, like a generated PDF object, to the client. When you use this method it is *required* that you also use .withMime() to specify the mime type.">
		<cfargument name="binaryData" required="true" hint="binary file data (eg a PDF object or image data) that you want to return to the client" />
		<cfreturn getRepInstance().setImageData(arguments.binaryData) />
	</cffunction>

	<cffunction name="saveLog">
		<cfargument name="exception" />
		<cfset logger = createObject("component", application._taffy.settings.exceptionLogAdapter).init(
				application._taffy.settings.exceptionLogAdapterConfig
		) />
		<cfset logger.saveLog(exception) />
	</cffunction>

	<cffunction name="queryToArray" access="private" returntype="array" output="false">
		<cfargument name="q" type="query" required="yes" />
		<cfscript>
			var local = {};
			if (structKeyExists(server, "railo")) {
				local.Columns = listToArray(arguments.q.getColumnList(false));
			}
			else {
				local.Columns = arguments.q.getMetaData().getColumnLabels();
			}
			local.QueryArray = ArrayNew(1);
			for (local.RowIndex = 1; local.RowIndex <= arguments.q.RecordCount; local.RowIndex++){
				local.Row = {};
				local.numCols = ArrayLen( local.Columns );
				for (local.ColumnIndex = 1; local.ColumnIndex <= local.numCols; local.ColumnIndex++){
					local.ColumnName = local.Columns[ local.ColumnIndex ];
					local.Row[ local.ColumnName ] = arguments.q[ local.ColumnName ][ local.RowIndex ];
				}
				ArrayAppend( local.QueryArray, local.Row );
			}
			return( local.QueryArray );
		</cfscript>
	</cffunction>

	<!---
		function that gets the representation class instance
		-- if the argument is blank, we use the default from taffy settings
		-- if the argument is a beanName, the bean is returned from the factory;
		-- otherwise it is assumed to be a cfc path and that cfc instance is returned
	--->
	<cffunction name="getRepInstance" access="private" output="false">
		<cfargument name="repClass" type="string" default="" />
		<cfif repClass eq "">
			<!--- recursion not the most efficient path here, but it's damn readable --->
			<cfreturn getRepInstance(application._taffy.settings.representationClass) />
		<cfelseif application._taffy.factory.containsBean(arguments.repClass)>
			<cfreturn application._taffy.factory.getBean(arguments.repClass) />
		<cfelse>
			<cfreturn createObject("component", arguments.repClass) />
		</cfif>
	</cffunction>

</cfcomponent>