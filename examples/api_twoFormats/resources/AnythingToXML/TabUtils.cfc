<cfcomponent displayname="TabUtils" namespace="TabUtils" output="no">
	<!--- Tab Utilities by Daniel Gaspar <daniel.gaspar@gmail.com> 5/1/2008 --->
	<!---  Keeps track of tabs 'n	prints them	-Dg--->
	<!--- 
	
		Copyright 2008 Daniel Gaspar Licensed under the Apache License, Version 2.0 (the "License");
		you may not use this file except in compliance with the License. You may obtain a copy of the
		License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or
		agreed to in writing, software distributed under the License is distributed on an "AS IS"
		BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
		for the specific language governing permissions and limitations under the License.
	
	
	--->
	<cfproperty name="tabs" default="0" type="numeric" />
	
	<cffunction name="init" access="public" output="no" returntype="any">
		<cfargument name="tabs" type="numeric" required="no" default="0" />
		<cfset this.tabs = arguments.tabs />	
		<cfreturn this>
	</cffunction>
	
	<cffunction name="setTabs" access="public" output="no" returntype="any">
		<cfargument name="tabs" type="numeric" required="no" default="#this.tabs#" />
		<cfset this.tabs = arguments.tabs />	
	</cffunction>
	
	<cffunction name="addtab" access="public" output="no" returntype="void">
		<cfargument name="num" type="numeric" required="no" default="1" />
		<cfset this.tabs = this.tabs  + arguments.num />		
	</cffunction>
	
	<cffunction name="removetab" access="public" output="no" returntype="void">
		<cfargument name="num" type="numeric" required="no" default="1" />
		<cfset this.tabs = this.tabs  - arguments.num />		
	</cffunction>	
		
	<cffunction name="printtabs" access="public" output="no" returntype="string" >
		<cfargument name="tabs" type="numeric" required="no" default="#this.tabs#" />
		<cfset var returnstring = "" />
		<cfset var i = 1 />	
		<!---<cfif this.tabs gt 0 >	--->
		<cfprocessingdirective suppresswhitespace="yes">
			<cfsetting enablecfoutputonly="yes">
			<cfsavecontent variable="returnstring" >				
				<cfoutput>#chr(10)#</cfoutput>				
				<cfloop from="1" to="#arguments.tabs#" index="i" >
					<cfoutput>#chr(09)#</cfoutput>
				</cfloop>				
			</cfsavecontent>
		</cfprocessingdirective>
		<!---</cfif>--->
		<cfreturn returnstring>
	</cffunction>
</cfcomponent>