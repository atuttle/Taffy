<cfcomponent output="false">
	<cfscript>
		//bean cache
		this.beans = structNew();
		//functionality
		function init(){
			return this;
		}
		function beanExists(beanName){
			if (structKeyExists(this.beans, arguments.beanName)){
				return true;
			}
			return false;
		}
		function getBean(beanName){
			if (beanExists(arguments.beanName)){
				return this.beans[arguments.beanName];
			}else{
				return false;
			}
		}
		function getBeanList(){
			return structKeyList(this.beans);
		}
	</cfscript>
	<cffunction name="loadBeansFromPath" access="public" output="false" returnType="void">
		<cfargument name="beanPath" type="string" required="true" hint="Absolute path to folder containing beans" />
		<cfset var beanQuery = '' />
		<cfset var beanName = '' />
		<!--- if the folder doesn't exist, do nothing --->
		<cfif not directoryExists(arguments.beanPath)>
			<cfreturn />
		</cfif>
		<!--- get list of beans to load --->
		<cfdirectory action="list" directory="#arguments.beanPath#" filter="*.cfc" name="beanQuery" />
		<!--- cache all of the beans --->
		<cfloop query="beanQuery">
			<cfset beanName = left(beanQuery.name, len(beanQuery.name)-4) /><!--- drop the ".cfc" --->
			<cfset this.beans[beanName] = createObject("component", "resources." & beanName) />
		</cfloop>
	</cffunction>
</cfcomponent>