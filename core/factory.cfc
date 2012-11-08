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
		<cfargument name="resourcesPath" type="string" default="resources" />
		<cfargument name="resourcesBasePath" type="string" default="" />
		<cfset var local = StructNew() />
		<!--- if the folder doesn't exist, do nothing --->
		<cfif not directoryExists(arguments.beanPath)>
			<cfreturn />
		</cfif>
		<!--- get list of beans to load --->
		<cfdirectory action="list" directory="#arguments.beanPath#" filter="*.cfc" name="local.beanQuery" recurse="true" />
		<!--- cache all of the beans --->
		<cfset application._taffy.status.skippedResources = arrayNew(1) /> <!--- empty out the array on factory reloads --->
		<cfloop query="local.beanQuery">
			<cfset local.beanName = filePathToBeanName(local.beanQuery.directory, local.beanquery.name, arguments.resourcesBasePath) />
			<cfset local.beanPath = filePathToBeanPath(local.beanQuery.directory, local.beanquery.name, arguments.resourcesBasePath) />
			<cftry>
				<cfset this.beans[local.beanName] = createObject("component", local.beanPath) />
				<cfcatch>
					<!--- skip cfc's with errors, but save info about them for display in the dashboard --->
					<cfset local.err = structNew() />
					<cfset local.err.resource = local.beanName />
					<cfset local.err.exception = cfcatch />
					<cfset arrayAppend(application._taffy.status.skippedResources, local.err) />
				</cfcatch>
			</cftry>
		</cfloop>
		<!--- resolve dependencies --->
		<cfloop list="#structKeyList(this.beans)#" index="local.b">
			<cfset local.beanMeta = getMetadata(this.beans[local.b]) />
			<cfset _recurse_ResolveDependencies(local.b, local.beanMeta) />
		</cfloop>
	</cffunction>

	<cffunction name="filePathToBeanPath" access="private">
		<cfargument name="path" />
		<cfargument name="filename" />
		<cfargument name="basepath" />
		<cfset var beanPath = 
			"resources."
			&
			replace(
				replace(path, basepath, ""), 
				"/",
				".",
				"ALL"
			)
			& 
			"."
			& 
			replace(
				filename,
				".cfc",
				""
			)
		/>
		<cfif left(beanPath, 1) eq ".">
			<cfset beanPath = right(beanPath, len(beanPath)-1) />
		</cfif>
		<cfreturn beanPath />
	</cffunction>

	<cffunction name="filePathToBeanName" access="private">
		<cfargument name="path" />
		<cfargument name="filename" />
		<cfargument name="basepath" />
		<cfreturn 
			replace(
				replace(path, basepath, ""), 
				"/",
				"",
				"ALL"
			)
			& replace(
				filename,
				".cfc",
				""
			)
		/>
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