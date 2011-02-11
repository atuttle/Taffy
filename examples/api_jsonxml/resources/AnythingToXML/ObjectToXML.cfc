<cfcomponent namespace="ObjectToXML" displayname="ObjectToXML" output="no" >
	<!--- Object to XML by Daniel Gaspar <daniel.gaspar@gmail.com> 5/1/2008 
				Thanks to Brian Rinaldi for getting the function introspection working. --->
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
		<cfargument name="XMLutils" type="any" required="yes" />
		<cfargument name="TabUtils" type="any" required="yes" />
		<cfset variables.Include_Type_Hinting = arguments.Include_Type_Hinting />
		<cfset variables.XMLutils = arguments.XMLutils />
		<cfset variables.TabUtils = arguments.TabUtils />
		<cfreturn this>
	</cffunction>		
	
	<cffunction name="setAnythingToXML" access="public" output="no" returntype="void">
		<cfargument name="AnythingToXML" type="any" required="yes" />
		<cfset variables.AnythingToXML = arguments.AnythingToXML />
	</cffunction>
						
	<cffunction name="ObjectToXML" access="public" output="no" returntype="string" >
		<cfargument name="ThisObj" type="any" required="yes">
		<cfargument name="rootNodeName" type="string" required="no" default="">
		<cfargument name="AttributeList" type="string" required="no" default="">
		<cfset var xmlString = "" />	
		<cfset var i = 1 />		
		<cfset var AttributeCollection = getMetaData(arguments.ThisObj).properties />													
		<cfsetting enablecfoutputonly="yes">
		<cfprocessingdirective suppresswhitespace="yes">
			<cfsavecontent variable="xmlString" >
						<cfoutput>#variables.TabUtils.printtabs()#</cfoutput>
						<cfoutput><#addNodeAttributes(arguments.rootNodeName,AttributeCollection,arguments.ThisObj,arguments.AttributeList)# <cfif variables.Include_Type_Hinting eq 1>CF_TYPE='object'</cfif>></cfoutput>
						<cfoutput>#createXML(arguments.ThisObj,arguments.rootNodeName,arguments.AttributeList)#</cfoutput>
						<cfoutput>#variables.TabUtils.printtabs()#</#variables.XMLutils.NodeNameCheck(arguments.rootNodeName)#></cfoutput>
			</cfsavecontent>
		</cfprocessingdirective>
		<cfreturn xmlString />
	</cffunction>
	
	<cffunction name="createXML" access="public" output="no" returntype="string">
		<cfargument name="ThisObj" type="any" required="yes">
		<cfargument name="rootNodeName" type="string" required="no" default="">
		<cfargument name="AttributeList" type="string" required="no" default="">
		<cfset var aProperties = getMetaData(ThisObj).properties />
		<cfset var aMethods = getMetaData(ThisObj).functions />
		<cfset var methodName = "" />
		<cfset var tmp = "" />
		<cfset var thisSize = ArrayLen(aProperties) />
		<cfset var xmlString = "" />	
		<cfset var i = 1 />
		<cfset var CurrentNode = '' />	
		<cfset variables.TabUtils.addtab() />				
		<cfsetting enablecfoutputonly="yes">
		<cfprocessingdirective suppresswhitespace="yes">
			<cfsavecontent variable="xmlString" >
				<cfloop from="1" to="#thisSize#" index="i" >			
					<cfset methodName = "get" & aProperties[i].name />
					<cfif structkeyexists(ThisObj, aProperties[i].name)>
						<cfif IsSimpleValue(evaluate("ThisObj." & aProperties[i].name))> 
							<cfif not ListFindNoCase(arguments.AttributeList,aProperties[i].name)>
								<cfset CurrentNode = variables.XMLutils.NodeNameCheck(aProperties[i].name) />
								<cfoutput>#variables.TabUtils.printtabs()#</cfoutput>
								<cfoutput><#CurrentNode#><![CDATA[#trim(evaluate("ThisObj." & aProperties[i].name))#]]></#CurrentNode#></cfoutput>					
							</cfif>
						<cfelse>
								<!--- Yay for Recursion!--->	
								<cfoutput>#variables.AnythingToXML.ToXML(ThisObj[aProperties[i].name], aProperties[i].name,arguments.AttributeList)#</cfoutput>
						</cfif>
					<cfelse>
						<cfif isdefined("ThisObj." & methodName) >
							<cfinvoke component="#ThisObj#" method="#methodName#" returnvariable="tmp" />
							<cfif IsSimpleValue(tmp)> 
								<cfif not ListFindNoCase(arguments.AttributeList,aProperties[i].name)>
									<cfset CurrentNode = variables.XMLutils.NodeNameCheck(aProperties[i].name) />
									<cfoutput>#variables.TabUtils.printtabs()#</cfoutput>
									<cfoutput><#CurrentNode#><![CDATA[#trim(tmp)#]]></#CurrentNode#></cfoutput>					
								</cfif>
							<cfelse>
									<!--- Yay for Recursion!--->	
									<cfoutput>#variables.AnythingToXML.ToXML(tmp, aProperties[i].name,arguments.AttributeList)#</cfoutput>
							</cfif>
						</cfif>
					</cfif>
				</cfloop>	
			</cfsavecontent>
		</cfprocessingdirective>		
		<cfset variables.TabUtils.removetab() />		
		<cfreturn xmlString />
	</cffunction>
	
	<cffunction name="addNodeAttributes" access="public" output="no" returntype="string"  >
		<cfargument name="thisNode" required="yes" type="string" hint="Name of XML the Tag" />
		<cfargument name="thisKeyList" required="yes" type="string" hint="List of Column names, Struct Keys, object properties" />		
		<cfargument name="thisElement" required="yes" type="any" hint="a Query or a Struct" />	
		<cfargument name="thisAttributeList" required="yes" type="string" hint="List of Column Names/Struct Keys that should become Attributes of the XML Node" />
		<cfset var returnString = variables.XMLutils.NodeNameCheck(arguments.thisNode) />
		<cfset var i = 1 />		
		
			
		<cfloop from="1" to="#arraylen(arguments.thisKeyList)#" index="j">
			<cfloop from="1"  to="#ListLen(arguments.thisAttributeList)#" index="i">		
				<cfif ListFindNoCase(arguments.thisKeyList[j].name, ListGetAt(arguments.thisAttributeList,i), ',' )>											
					<cfset returnString = returnString & ' ' & lCase(ListGetAt(arguments.thisAttributeList,i)) & '="' />				
					<cfset returnString = returnString & xmlformat(evaluate("arguments.thisElement." & ListGetAt(arguments.thisAttributeList,i))) & '"' />			
				</cfif>
			</cfloop>
		</cfloop>		
						
		<cfreturn returnString />
	</cffunction>
				
</cfcomponent>