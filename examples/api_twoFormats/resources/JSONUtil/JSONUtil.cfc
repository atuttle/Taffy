<!---

Copyright 2009 Nathan Mische

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

    http://www.apache.org/licenses/LICENSE-2.0 
	
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 

--->
<cfcomponent displayname="JSONUtil" output="false">

	<cfset this.deserialzeJSON = deserializeFromJSON />
	<cfset this.serializeJSON = serializeToJSON />	
	
	<cfset this.deserialize = deserializeFromJSON />
	<cfset this.serialize = serializeToJSON />
	
	<cffunction name="init" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction 
		name="deserializeFromJSON" 
		access="public" 
		returntype="any" 
		output="false" 
		hint="Converts a JSON (JavaScript Object Notation) string data representation into CFML data, such as a CFML structure or array.">
		<cfargument 
			name="JSONVar" 
			type="string" 
			required="true" 
			hint="A string that contains a valid JSON construct, or variable that represents one." />
		<cfargument 
			name="strictMapping" 
			type="boolean" 
			required="false" 
			default="true" 
			hint="A Boolean value that specifies whether to convert the JSON strictly, as follows: 
				<ul>
					<li><code>true:</code> (Default) Convert the JSON string to ColdFusion data types that correspond directly to the JSON data types.</li>
					<li><code>false:</code> Determine if the JSON string contains representations of ColdFusion queries, and if so, convert them to queries.</li>
				</ul>" />	
		
		<!--- DECLARE VARIABLES --->
		<cfset var ar = ArrayNew(1) />
		<cfset var st = StructNew() />
		<cfset var dataType = "" />
		<cfset var inQuotes = false />
		<cfset var startPos = 1 />
		<cfset var nestingLevel = 0 />
		<cfset var dataSize = 0 />
		<cfset var i = 1 />
		<cfset var skipIncrement = false />
		<cfset var j = 0 />
		<cfset var char = "" />
		<cfset var dataStr = "" />
		<cfset var structVal = "" />
		<cfset var structKey = "" />
		<cfset var colonPos = "" />
		<cfset var qRows = 0 />
		<cfset var qCols = "" />
		<cfset var qCol = "" />
		<cfset var qData = "" />
		<cfset var curCharIndex = "" />
		<cfset var curChar = "" />
		<cfset var result = "" />
		<cfset var unescapeVals = "\\,\"",\/,\b,\t,\n,\f,\r" />
		<cfset var unescapeToVals = "\,"",/,#Chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#" />
		<cfset var unescapeVals2 = '\,",/,b,t,n,f,r' />
		<cfset var unescapetoVals2 = '\,",/,#Chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#' />
		<cfset var dJSONString = "" />
		
		<cfset var _data = Trim(arguments.JSONVar) />
		
		<!--- NUMBER --->
		<cfif IsNumeric(_data)>
			<cfreturn Val(_data) />
		
		<!--- NULL --->
		<cfelseif _data EQ "null">
			<cfreturn "null" />
		
		<!--- BOOLEAN --->
		<cfelseif ListFindNoCase("true,false", _data)>
			<cfreturn _data />
		
		<!--- EMPTY STRING --->
		<cfelseif _data EQ "''" OR _data EQ '""'>
			<cfreturn "" />
		
		<!--- STRING --->
		<cfelseif ReFind('^"[^\\"]*(?:\\.[^\\"]*)*"$', _data) EQ 1 OR ReFind("^'[^\\']*(?:\\.[^\\']*)*'$", _data) EQ 1>
			<cfset _data = mid(_data, 2, Len(_data)-2) />
			<!--- If there are any \b, \t, \n, \f, and \r, do extra processing
				(required because ReplaceList() won't work with those) --->
			<cfif Find("\b", _data) OR Find("\t", _data) OR Find("\n", _data) OR Find("\f", _data) OR Find("\r", _data)>
				<cfset curCharIndex = 0 />
				<cfset curChar =  ""/>
				<cfset dJSONString = ArrayNew(1) />
				<cfloop condition="true">
					<cfset curCharIndex = curCharIndex + 1 />
					<cfif curCharIndex GT len(_data)>
						<cfbreak />
					<cfelse>
						<cfset curChar = mid(_data, curCharIndex, 1) />
						<cfif curChar EQ "\">
							<cfset curCharIndex = curCharIndex + 1 />
							<cfset curChar = mid(_data, curCharIndex,1) />
							<cfset pos = listFind(unescapeVals2, curChar) />
							<cfif pos>
								<cfset ArrayAppend(dJSONString,ListGetAt(unescapetoVals2, pos)) />
							<cfelse>
								<cfset ArrayAppend(dJSONString,"\" & curChar) />
							</cfif>
						<cfelse>
							<cfset ArrayAppend(dJSONString,curChar) />
						</cfif>
					</cfif>
				</cfloop>
				
				<cfreturn ArrayToList(dJSONString,"") />
			<cfelse>
				<cfreturn ReplaceList(_data, unescapeVals, unescapeToVals) />
			</cfif>
		
		<!--- ARRAY, STRUCT, OR QUERY --->
		<cfelseif ( Left(_data, 1) EQ "[" AND Right(_data, 1) EQ "]" )
			OR ( Left(_data, 1) EQ "{" AND Right(_data, 1) EQ "}" )>
			
			<!--- Store the data type we're dealing with --->
			<cfif Left(_data, 1) EQ "[" AND Right(_data, 1) EQ "]">
				<cfset dataType = "array" />
			<cfelseif ReFindNoCase('^\{"ROWCOUNT":[0-9]+,"COLUMNS":\[("[^"]+",?)+\],"DATA":\{("[^"]+":\[[^]]*\],?)+\}\}$', _data, 0) EQ 1 AND NOT arguments.strictMapping>
				<cfset dataType = "queryByColumns" />
			<cfelseif ReFindNoCase('^\{"COLUMNS":\[("[^"]+",?)+\],"DATA":\[(\[[^]]*\],?)+\]\}$', _data, 0) EQ 1 AND NOT arguments.strictMapping>
				<cfset dataType = "query" />
			<cfelse>
				<cfset dataType = "struct" />
			</cfif>
			
			<!--- Remove the brackets --->
			<cfset _data = Trim( Mid(_data, 2, Len(_data)-2) ) />
			
			<!--- Deal with empty array/struct --->
			<cfif Len(_data) EQ 0>
				<cfif dataType EQ "array">
					<cfreturn ar />
				<cfelse>
					<cfreturn st />
				</cfif>
			</cfif>
			
			<!--- Loop through the string characters --->
			<cfset dataSize = Len(_data) + 1 />
			<cfloop condition="#i# LTE #dataSize#">
				<cfset skipIncrement = false />
				<!--- Save current character --->
				<cfset char = Mid(_data, i, 1) />
				
				<!--- If char is a quote, switch the quote status --->
				<cfif char EQ '"'>
					<cfset inQuotes = NOT inQuotes />
				<!--- If char is escape character, skip the next character --->
				<cfelseif char EQ "\" AND inQuotes>
					<cfset i = i + 2 />
					<cfset skipIncrement = true />
				<!--- If char is a comma and is not in quotes, or if end of string, deal with data --->
				<cfelseif (char EQ "," AND NOT inQuotes AND nestingLevel EQ 0) OR i EQ Len(_data)+1>
					<cfset dataStr = Mid(_data, startPos, i-startPos) />
					
					<!--- If data type is array, append data to the array --->
					<cfif dataType EQ "array">
						<cfset arrayappend( ar, deserializeFromJSON(dataStr, arguments.strictMapping) ) />
					<!--- If data type is struct or query or queryByColumns... --->
					<cfelseif dataType EQ "struct" OR dataType EQ "query" OR dataType EQ "queryByColumns">
						<cfset dataStr = Mid(_data, startPos, i-startPos) />
						<cfset colonPos = Find('":', dataStr) />
						<cfif colonPos>
							<cfset colonPos = colonPos + 1 />	
						<cfelse>
							<cfset colonPos = Find(":", dataStr) />	
						</cfif>
						<cfset structKey = Trim( Mid(dataStr, 1, colonPos-1) ) />
						
						<!--- If needed, remove quotes from keys --->
						<cfif Left(structKey, 1) EQ "'" OR Left(structKey, 1) EQ '"'>
							<cfset structKey = Mid( structKey, 2, Len(structKey)-2 ) />
						</cfif>
						
						<cfset structVal = Mid( dataStr, colonPos+1, Len(dataStr)-colonPos ) />
						
						<!--- If struct, add to the structure --->
						<cfif dataType EQ "struct">
							<cfset StructInsert( st, structKey, deserializeFromJSON(structVal, arguments.strictMapping) ) />
						
						<!--- If query, build the query --->
						<cfelseif dataType EQ "queryByColumns">
							<cfif structKey EQ "rowcount">
								<cfset qRows = deserializeFromJSON(structVal, arguments.strictMapping) />
							<cfelseif structKey EQ "columns">								
								<cfset qCols = deserializeFromJSON(structVal, arguments.strictMapping) />
								<cfset st = QueryNew(ArrayToList(qCols)) />
								<cfif qRows>
									<cfset QueryAddRow(st, qRows) />
								</cfif>
							<cfelseif structKey EQ "data">
								<cfset qData = deserializeFromJSON(structVal, arguments.strictMapping) />
								<cfset ar = StructKeyArray(qData) />
								<cfloop from="1" to="#ArrayLen(ar)#" index="j">
									<cfloop from="1" to="#st.recordcount#" index="qRows">
										<cfset qCol = ar[j] />
										<cfset QuerySetCell(st, qCol, qData[qCol][qRows], qRows) />
									</cfloop>
								</cfloop>
							</cfif>
						<cfelseif dataType EQ "query">
							<cfif structKey EQ "columns">
								<cfset qCols = deserializeFromJSON(structVal, arguments.strictMapping) />
								<cfset st = QueryNew(ArrayToList(qCols)) />
							<cfelseif structKey EQ "data">
								<cfset qData = deserializeFromJSON(structVal, arguments.strictMapping) />
								<cfloop from="1" to="#ArrayLen(qData)#" index="qRows">
									<cfset QueryAddRow(st) />
									<cfloop from="1" to="#ArrayLen(qCols)#" index="j">
										<cfset qCol = qCols[j] />
										<cfset QuerySetCell(st, qCol, qData[qRows][j], qRows) />
									</cfloop>
								</cfloop>
							</cfif>
						</cfif>
					</cfif>
					
					<cfset startPos = i + 1 />
				<!--- If starting a new array or struct, add to nesting level --->
				<cfelseif "{[" CONTAINS char AND NOT inQuotes>
					<cfset nestingLevel = nestingLevel + 1 />
				<!--- If ending an array or struct, subtract from nesting level --->
				<cfelseif "]}" CONTAINS char AND NOT inQuotes>
					<cfset nestingLevel = nestingLevel - 1 />
				</cfif>
				
				<cfif NOT skipIncrement>
					<cfset i = i + 1 />
				</cfif>
			</cfloop>
			
			<!--- Return appropriate value based on data type --->
			<cfif dataType EQ "array">
				<cfreturn ar />
			<cfelse>
				<cfreturn st />
			</cfif>
		
		<!--- INVALID JSON --->
		<cfelse>
			<cfthrow message="JSON parsing failure." />
		</cfif>
	</cffunction>
	
	<cffunction 
		name="serializeToJSON" 
		access="public" 
		returntype="string" 
		output="false"
		hint="Converts ColdFusion data into a JSON (JavaScript Object Notation) representation of the data.">
		<cfargument 
			name="var" 
			type="any" 
			required="true"
			hint="A ColdFusion data value or variable that represents one." />
		<cfargument
			name="serializeQueryByColumns"
			type="boolean"
			required="false"
			default="false"
			hint="A Boolean value that specifies how to serialize ColdFusion queries.
				<ul>
					<li><code>false</code>: (Default) Creates an object with two entries: an array of column names and an array of row arrays. This format is required by the HTML format cfgrid tag.</li>
					<li><code>true</code>: Creates an object that corresponds to WDDX query format.</li>
				</ul>">
		<cfargument 
			name="strictMapping" 
			type="boolean" 
			required="false" 
			default="false" 
			hint="A Boolean value that specifies whether to convert the ColdFusion data strictly, as follows: 
				<ul>
					<li><code>false:</code> (Default) Convert the ColdFusion data to a JSON string using ColdFusion data types.</li>
					<li><code>true:</code> Convert the ColdFusion data to a JSON string using underlying Java/SQL data types.</li>					
				</ul>" />
		
		<!--- VARIABLE DECLARATION --->
		<cfset var jsonString = "" />
		<cfset var tempVal = "" />
		<cfset var arKeys = "" />
		<cfset var colPos = 1 />
		<cfset var md = "" />
		<cfset var rowDel = "" />
		<cfset var colDel = "" />
		<cfset var className = "" />
		<cfset var i = 1 />
		<cfset var column = "" />
		<cfset var datakey = "" />
		<cfset var recordcountkey = "" />
		<cfset var columnlist = "" />
		<cfset var columnlistkey = "" />
		<cfset var columnJavaTypes = "" />
		<cfset var dJSONString = "" />
		<cfset var escapeToVals = "\\,\"",\/,\b,\t,\n,\f,\r" />
		<cfset var escapeVals = "\,"",/,#Chr(8)#,#Chr(9)#,#Chr(10)#,#Chr(12)#,#Chr(13)#" />
		
		<cfset var _data = arguments.var />
		
		<cfif arguments.strictMapping>		
			<!--- GET THE CLASS NAME --->			
			<cfset className = getClassName(_data) />							
		</cfif>
			
		<!--- TRY STRICT MAPPING --->
		
		<cfif Len(className) AND CompareNoCase(className,"java.lang.String") eq 0>
			<cfreturn '"' & ReplaceList(_data, escapeVals, escapeToVals) & '"' />
		
		<cfelseif Len(className) AND CompareNoCase(className,"java.lang.Boolean") eq 0>
			<cfreturn ReplaceList(ToString(_data), 'YES,NO', 'true,false') />
		
		<cfelseif Len(className) AND CompareNoCase(className,"java.lang.Integer") eq 0>
			<cfreturn ToString(_data) />
			
		<cfelseif Len(className) AND CompareNoCase(className,"java.lang.Long") eq 0>
			<cfreturn ToString(_data) />
			
		<cfelseif Len(className) AND CompareNoCase(className,"java.lang.Float") eq 0>
			<cfreturn ToString(_data) />
			
		<cfelseif Len(className) AND CompareNoCase(className,"java.lang.Double") eq 0>
			<cfreturn ToString(_data) />				
		
		<!--- BINARY --->
		<cfelseif IsBinary(_data)>
			<cfthrow message="JSON serialization failure: Unable to serialize binary data to JSON." />
		
		<!--- BOOLEAN --->
		<cfelseif IsBoolean(_data) AND NOT IsNumeric(_data)>
			<cfreturn ReplaceList(YesNoFormat(_data), 'Yes,No', 'true,false') />			
			
		<!--- NUMBER --->
		<cfelseif IsNumeric(_data)>
			<cfif getClassName(_data) eq "java.lang.String">
				<cfreturn Val(_data).toString() />
			<cfelse>
				<cfreturn _data.toString() />
			</cfif>
		
		<!--- DATE --->
		<cfelseif IsDate(_data)>
			<cfreturn '"#DateFormat(_data, "mmmm, dd yyyy")# #TimeFormat(_data, "HH:mm:ss")#"' />
		
		<!--- STRING --->
		<cfelseif IsSimpleValue(_data)>
			<cfreturn '"' & ReplaceList(_data, escapeVals, escapeToVals) & '"' />
			
		<!--- RAILO XML --->
		<cfelseif StructKeyExists(server,"railo") and IsXML(_data)>
			<cfreturn '"' & ReplaceList(ToString(_data), escapeVals, escapeToVals) & '"' />
		
		<!--- CUSTOM FUNCTION --->
		<cfelseif IsCustomFunction(_data)>			
			<cfreturn serializeToJSON( GetMetadata(_data), arguments.serializeQueryByColumns, arguments.strictMapping) />
			
		<!--- OBJECT --->
		<cfelseif IsObject(_data)>		
			<cfreturn "{}" />		
		
		<!--- ARRAY --->
		<cfelseif IsArray(_data)>
			<cfset dJSONString = ArrayNew(1) />
			<cfloop from="1" to="#ArrayLen(_data)#" index="i">
				<cfset tempVal = serializeToJSON( _data[i], arguments.serializeQueryByColumns, arguments.strictMapping ) />
				<cfset ArrayAppend(dJSONString,tempVal) />
			</cfloop>	
					
			<cfreturn "[" & ArrayToList(dJSONString,",") & "]" />
		
		<!--- STRUCT --->
		<cfelseif IsStruct(_data)>
			<cfset dJSONString = ArrayNew(1) />
			<cfset arKeys = StructKeyArray(_data) />
			<cfloop from="1" to="#ArrayLen(arKeys)#" index="i">
				<cfset tempVal = serializeToJSON(_data[ arKeys[i] ], arguments.serializeQueryByColumns, arguments.strictMapping ) />
				<cfset ArrayAppend(dJSONString,'"' & arKeys[i] & '":' & tempVal) />
			</cfloop>
						
			<cfreturn "{" & ArrayToList(dJSONString,",") & "}" />
		
		<!--- QUERY --->
		<cfelseif IsQuery(_data)>
			<cfset dJSONString = ArrayNew(1) />
			
			<!--- Add query meta data --->
			<cfset recordcountKey = "ROWCOUNT" />
			<cfset columnlistKey = "COLUMNS" />
			<cfset columnlist = "" />
			<cfset dataKey = "DATA" />
			<cfset md = GetMetadata(_data) />
			<cfset columnJavaTypes = StructNew() />					
			<cfloop from="1" to="#ArrayLen(md)#" index="column">
				<cfset columnlist = ListAppend(columnlist,UCase(md[column].Name),',') />
				<cfif StructKeyExists(md[column],"TypeName")>
					<cfset columnJavaTypes[md[column].Name] = getJavaType(md[column].TypeName) />
				<cfelse>
					<cfset columnJavaTypes[md[column].Name] = "" />
				</cfif>
			</cfloop>				
			
			<cfif arguments.serializeQueryByColumns>
				<cfset ArrayAppend(dJSONString,'"#recordcountKey#":' & _data.recordcount) />
				<cfset ArrayAppend(dJSONString,',"#columnlistKey#":[' & ListQualify(columnlist, '"') & ']') />
				<cfset ArrayAppend(dJSONString,',"#dataKey#":{') />
				<cfset colDel = "">
				<cfloop list="#columnlist#" delimiters="," index="column">
					<cfset ArrayAppend(dJSONString,colDel) />
					<cfset ArrayAppend(dJSONString,'"#column#":[') />
					<cfset rowDel = "">	
					<cfloop from="1" to="#_data.recordcount#" index="i">
						<cfset ArrayAppend(dJSONString,rowDel) />
						<cfif (arguments.strictMapping or StructKeyExists(server,"railo")) AND Len(columnJavaTypes[column])>
							<cfset tempVal = serializeToJSON( JavaCast(columnJavaTypes[column],_data[column][i]), arguments.serializeQueryByColumns, arguments.strictMapping ) />
						<cfelse>
							<cfset tempVal = serializeToJSON( _data[column][i], arguments.serializeQueryByColumns, arguments.strictMapping ) />
						</cfif>							
						<cfset ArrayAppend(dJSONString,tempVal) />
						<cfset rowDel = ",">	
					</cfloop>
					<cfset ArrayAppend(dJSONString,']') />
					<cfset colDel = ",">
				</cfloop>				
				<cfset ArrayAppend(dJSONString,'}') />			
			<cfelse>			
				<cfset ArrayAppend(dJSONString,'"#columnlistKey#":[' & ListQualify(columnlist, '"') & ']') />
				<cfset ArrayAppend(dJSONString,',"#dataKey#":[') />				
				<cfset rowDel = "">
				<cfloop from="1" to="#_data.recordcount#" index="i">
					<cfset ArrayAppend(dJSONString,rowDel) />
					<cfset ArrayAppend(dJSONString,'[') />
					<cfset colDel = "">					
					<cfloop list="#columnlist#" delimiters="," index="column">
						<cfset ArrayAppend(dJSONString,colDel) />
						<cfif (arguments.strictMapping or StructKeyExists(server,"railo")) AND Len(columnJavaTypes[column])>
							<cfset tempVal = serializeToJSON( JavaCast(columnJavaTypes[column],_data[column][i]), arguments.serializeQueryByColumns, arguments.strictMapping ) />
						<cfelse>
							<cfset tempVal = serializeToJSON( _data[column][i], arguments.serializeQueryByColumns, arguments.strictMapping ) />
						</cfif>	
						<cfset ArrayAppend(dJSONString,tempVal) />
						<cfset colDel=","/>
					</cfloop>					
					<cfset ArrayAppend(dJSONString,']') />
					<cfset rowDel = "," />
				</cfloop>				
				<cfset ArrayAppend(dJSONString,']') />			
			</cfif>
			
			<cfreturn "{" & ArrayToList(dJSONString,"") & "}">
			
		<!--- XML --->
		<cfelseif IsXML(_data)>
			<cfreturn '"' & ReplaceList(ToString(_data), escapeVals, escapeToVals) & '"' />
					
		
		<!--- UNKNOWN OBJECT TYPE --->
		<cfelse>
			<cfreturn "{}" />
		</cfif>
		
	</cffunction>
	
	<cffunction 
		name="getJavaType"
		access="private" 
		returntype="string" 
		output="false"
		hint="Maps SQL to Java types. Returns blank string for unhandled SQL types.">
		<cfargument 
			name="sqlType" 
			type="string" 
			required="true"
			hint="A SQL datatype." />			
		
		<cfswitch expression="#arguments.sqlType#">
					
			<cfcase value="bit">
				<cfreturn "boolean" />
			</cfcase>
			
			<cfcase value="tinyint,smallint,integer">
				<cfreturn "int" />
			</cfcase>
			
			<cfcase value="bigint">
				<cfreturn "long" />
			</cfcase>
			
			<cfcase value="real,float">
				<cfreturn "float" />
			</cfcase>
			
			<cfcase value="double">
				<cfreturn "double" />
			</cfcase>
			
			<cfcase value="char,varchar,longvarchar">
				<cfreturn "string" />
			</cfcase>
			
			<cfdefaultcase>
				<cfreturn "" />
			</cfdefaultcase>
		
		</cfswitch>
		
	</cffunction>
	
	<cffunction 
		name="getClassName"
		access="private" 
		returntype="string" 
		output="false"
		hint="Returns a variable's underlying java Class name.">
		<cfargument 
			name="data" 
			type="any" 
			required="true"
			hint="A variable." />
			
		<!--- GET THE CLASS NAME --->			
		<cftry>				
			<cfreturn arguments.data.getClass().getName() />			
			<cfcatch type="any">
				<cfreturn "" />
			</cfcatch>			
		</cftry>
		
	</cffunction>
	
</cfcomponent>