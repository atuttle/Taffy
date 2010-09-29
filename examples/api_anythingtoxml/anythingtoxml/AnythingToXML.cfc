<cfcomponent displayname="AnythingToXML" namespace="AnythingToXML" output="no">
	<!--- Anything To XML by Daniel Gaspar <daniel.gaspar@gmail.com> 5/1/2008 --->
	<!--- 
	
		Copyright 2008 Daniel Gaspar Licensed under the Apache License, Version 2.0 (the "License");
		you may not use this file except in compliance with the License. You may obtain a copy of the
		License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or
		agreed to in writing, software distributed under the License is distributed on an "AS IS"
		BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
		for the specific language governing permissions and limitations under the License.
	
	
	--->
		
	<cffunction name="init" access="public" output="no" returntype="any">
		<cfargument name="Include_Type_Hinting" type="numeric" required="no" default="1" />
		<cfset variables.TabUtils =	createObject('component', 'TabUtils').init() />		
		<cfset variables.XMLutils =	createObject('component', 'XMLutils').init() />			
		<cfset variables.StructToXML = createObject('component','StructToXML').init(arguments.Include_Type_Hinting,XMLutils,TabUtils) />
		<cfset variables.QueryToXML = createObject('component','QueryToXML').init(arguments.Include_Type_Hinting,XMLutils,TabUtils) />
		<cfset variables.ArrayToXML = createObject('component','ArrayToXML').init(arguments.Include_Type_Hinting,XMLutils,TabUtils) />
		<cfset variables.ObjectToXML = createObject('component','ObjectToXML').init(arguments.Include_Type_Hinting,XMLutils,TabUtils) />
		<cfset variables.Include_Type_Hinting = arguments.Include_Type_Hinting />		
		<cfset variables.StructToXML.setAnythingToXML(this) />
		<cfset variables.QueryToXML.setAnythingToXML(this) />
		<cfset variables.ArrayToXML.setAnythingToXML(this) />
		<cfset variables.ObjectToXML.setAnythingToXML(this) />											
		<cfreturn this>
	</cffunction>
	
	<cffunction name="ToXML" access="public" output="no" returntype="string" hint="This function converts simple types, arrays, queries, structures, objects with properties, or any combination of these to XML">
		<cfargument name="ThisItem" type="any" required="yes" hint="simple type, array, query, structure, object with properties, or any combination of previous">
		<cfargument name="NodeName" type="string" required="no" default="XML_ELEMENT" hint="name of a node">	
		<cfargument name="AttributeList" type="string" required="no" default="" hint="List of Column Names/Struct Keys that should become Attributes of the XML Node" />	
		<cfset var returnstring = "">				

		<!---initalize cfc if it is not  --->	
		<cfif not structkeyexists(variables, "TabUtils") >
			<cfset init() />
		</cfif>
	
		<!--- If this is the 1st time add XML encoding. Comment this out for Debugging --->
		<cfif variables.TabUtils.tabs eq 0 >
			<!---cfcontent type="text/xml; charset=utf-8">--->
			<cfset returnstring = '<?xml version="1.0" encoding="utf-8"?>' />
		</cfif>
	
		<!--- Decide how to create the XML --->
		<cfif isSimpleValue(ThisItem) >
			<cfset returnstring = returnstring & "#variables.TabUtils.printtabs()#<#variables.XMLutils.NodeNameCheck(arguments.NodeName)#><![CDATA[#trim(ThisItem)#]]></#variables.XMLutils.NodeNameCheck(arguments.NodeName)#>" />	
		<cfelseif isArray(ThisItem)>
			<cfset returnstring = returnstring & variables.ArrayToXML.ArrayToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>		
		<cfelseif isQuery(ThisItem)>		
			<cfset returnstring = returnstring & variables.QueryToXML.QueryToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
		<cfelseif structkeyexists(getMetaData(ThisItem), "properties") > 				
			<cfset returnstring = returnstring & variables.ObjectToXML.ObjectToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
		<cfelseif isStruct(ThisItem)>
			<cfset returnstring = returnstring & variables.StructToXML.StructToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
		<cfelseif IsCustomFunction(ThisItem)>
			<!--- ignore --->
		<cfelse>
			<cfset returnstring = returnstring & "#variables.TabUtils.printtabs()#<ERROR>Unable to Convert this element to XML</ERROR>" />
			<!---<cfdump var="#arguments.ThisItem#" /><cfabort />--->
		</cfif>
		
		<cfreturn returnstring>
	</cffunction>
			
</cfcomponent>