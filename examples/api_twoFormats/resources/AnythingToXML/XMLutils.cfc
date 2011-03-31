<cfcomponent displayname="XMLutils" namespace="XMLutils" output="no">
	<!--- XML Utility functions by Daniel Gaspar <daniel.gaspar@gmail.com> 5/1/2008 --->
	<!--- Global functionality for XML creation: deciding on plural node names -Dg--->
	<!--- 
	
		Copyright 2008 Daniel Gaspar Licensed under the Apache License, Version 2.0 (the "License");
		you may not use this file except in compliance with the License. You may obtain a copy of the
		License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or
		agreed to in writing, software distributed under the License is distributed on an "AS IS"
		BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
		for the specific language governing permissions and limitations under the License.
	
	
	--->
	<cffunction name="init" access="public" output="no" returntype="any">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="getNodePlural" access="public" output="no" >
		<cfargument name="ThisNode" type="string" required="yes" />
		<cfset var Plural = "" />	
		
		<cfif PluralExceptions(ThisNode) neq "" >
			<cfset plural = PluralExceptions(ThisNode)>
		<cfelseif right(ThisNode,2) eq 'ey'>
			<cfset plural = left(ThisNode,(len(ThisNode)-2)) & "IES" />
		<cfelseif right(ThisNode,1) eq 'y'>
			<cfset plural = left(ThisNode,(len(ThisNode)-1)) & "IES" />
		<cfelseif right(ThisNode,1) eq 's'>
			<cfset plural = ThisNode & "ES" />
		<cfelse>
			<cfset Plural = ThisNode & "S" />
		</cfif>
		<cfreturn NodeNameCheck(Plural) />
	</cffunction>
	
	<cffunction name="PluralExceptions" access="private" output="no" >
		<cfargument name="ThisNode" type="string" required="yes" />
		<cfset var Plural = "" />	
		<!--- 1st pass at naming.  --->
		<cfswitch expression="#ucase(arguments.ThisNode)#">
			<cfcase value="SURVEY">
				<cfset Plural = "SURVEYS" />	
			</cfcase>			
			<cfcase value="METADATA">
				<cfset Plural = "METADATA" />	
			</cfcase>
			<cfdefaultcase>
				<cfset Plural = "" />	
			</cfdefaultcase>
		</cfswitch>
		<cfreturn ucase(Plural) />
	</cffunction>
	
	<cffunction name="NodeNameCheck" access="public" output="no" >
		<cfargument name="ThisNode" type="string" required="yes" />
		<cfset var rename = "" />	
		<!--- For adding hacks/ renaming nodes. --->
		<!--- 
			A trick here is that you could let things get missnamed in the plural exceptions list, 
			then fix them here if you need to. 
			For example: 
				"related_images" plural is "related_imageses" the sub-node of this is "related_image" which plural is "related_images" 
				We'd need to let "related_images" get missnamed then fix both afterwards so that we can filter properly. 
			--->
		<cfswitch expression="#ucase(arguments.ThisNode)#">
			<cfcase value="IMAGESES">
				<cfset rename = "IMAGES" />	
			</cfcase>
			<cfcase value="IMAGES">
				<cfset rename = "IMAGE" />	
			</cfcase>
			<cfdefaultcase>
				<cfset rename = arguments.ThisNode />	
			</cfdefaultcase>
		</cfswitch>
		<cfreturn ucase(rename) />
	</cffunction>
</cfcomponent>