<cfcomponent output="false">
	<cfscript>
		//bean cache
		this.beans = structNew();
		//functionality
		function init(){
			return this;
		}
		// Proxy to beanExists to provide similar interface to ColdSpring
		function containsBean(beanName){
			return beanExists(arguments.beanName);
		}
		function beanExists(beanName){
			return structKeyExists(this.beans, arguments.beanName);
		}
		function getBean(beanName){
			if (beanExists(arguments.beanName)){
				return this.beans[arguments.beanName];
			}else{
				throwError(message="Bean name '#arguments.beanName#' not found.", type="Taffy.Factory.BeanNotFound");
			}
		}
		function getBeanList(){
			return structKeyList(this.beans);
		}
	</cfscript>
	<cffunction name="loadBeansFromPath" access="public" output="false" returnType="void">
		<cfargument name="beanPath" type="string" required="true" hint="Absolute path to folder containing beans" />
		<cfset var local = StructNew() />
		<!--- if the folder doesn't exist, do nothing --->
		<cfif not directoryExists(arguments.beanPath)>
			<cfreturn />
		</cfif>
		<!--- get list of beans to load --->
		<cfdirectory action="list" directory="#arguments.beanPath#" filter="*.cfc" name="local.beanQuery" />
		<!--- cache all of the beans --->
		<cfloop query="local.beanQuery">
			<cfset local.beanName = left(local.beanQuery.name, len(local.beanQuery.name)-4) /><!--- drop the ".cfc" --->
			<cfset this.beans[local.beanName] = createObject("component", "resources." & local.beanName) />
		</cfloop>
		<!--- resolve dependencies --->
		<cfloop list="#structKeyList(this.beans)#" index="local.b">
			<cfset local.beanMeta = getMetadata(this.beans[local.b]) />
			<cfset _recurse_ResolveDependencies(local.b, local.beanMeta) />
		</cfloop>
	</cffunction>
	<cffunction name="_recurse_ResolveDependencies" access="private">
		<cfargument name="beanName" type="string" required="true" />
		<cfargument name="metaData" type="struct" required="true" />
		<cfset var local = structNew() />
		<cfif structKeyExists(arguments.metaData, "functions") and isArray(arguments.metaData.functions)>
			<cfloop from="1" to="#arrayLen(arguments.metaData.functions)#" index="local.f">
				<cfset local.fname = arguments.metaData.functions[local.f].name />
				<cfif len(local.fname) gt 3>
					<cfset local.propName = right(local.fname, len(local.fname)-3) />
					<cfif left(local.fname, 3) eq "set" and beanExists(local.propName)>
						<cfset evaluate("this.beans['#arguments.beanName#'].#local.fname#(getBean('#local.propName#'))") />
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<cfif structKeyExists(arguments.metaData, "extends") and isStruct(arguments.metaData.extends)>
			<cfset _recurse_ResolveDependencies(arguments.beanName, arguments.metaData.extends) />
		</cfif>
	</cffunction>
	<!--- proxy function for CF8 compatibility --->
	<cffunction name="throwError">
		<cfthrow attributecollection="#arguments#" />
	</cffunction>

</cfcomponent>