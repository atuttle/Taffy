<cfcomponent output="false">
	<cfscript>
		//bean cache
		this.beans = structNew();
		this.transients = structNew();
		//functionality
		function init(){
			return this;
		}
		// Proxy to beanExists to provide similar interface to ColdSpring
		function containsBean(beanName){
			return beanExists(arguments.beanName);
		}
		function transientExists(beanName){
			return structKeyExists(this.transients, arguments.beanName);
		}
		function getBean(beanName){
			if (beanExists(arguments.beanName, false)){
				return this.beans[arguments.beanName];
			}else if (transientExists(arguments.beanName)){
				return createObject('component', this.transients[arguments.beanName]);
			}else{
				throwError(message="Bean name '#arguments.beanName#' not found.", type="Taffy.Factory.BeanNotFound");
			}
		}
		function getBeanList(){
			var combined = structKeyList(this.beans);
			var trans = structKeyList(this.transients);
			if (len(combined) and len(trans)){
				combined = combined & ",";
			}
			combined = combined & trans;
			return combined;
		}
	</cfscript>
	<cffunction name="beanExists" output="false">
		<cfargument required="true" name="beanName">
		<cfargument name="includeTransients" default="true">
		<cfscript>
			return structKeyExists(this.beans, arguments.beanName) or (includeTransients and transientExists(arguments.beanName));
		</cfscript>
	</cffunction>
	<cffunction name="loadBeansFromPath" access="public" output="false" returnType="void">
		<cfargument name="beanPath" type="string" required="true" hint="Absolute path to folder containing beans" />
		<cfargument name="resourcesPath" type="string" default="resources" />
		<cfargument name="resourcesBasePath" type="string" default="" />
		<cfargument name="isFullReload" type="boolean" default="false" />
		<cfset var local = StructNew() />
		<!--- cache all of the beans --->
		<cfif isFullReload>
			<cfset this.beans = structNew() />
			<cfset application._taffy.status.skippedResources = arrayNew(1) /> <!--- empty out the array on factory reloads --->
			<cfset application._taffy.beanList = "" />
		</cfif>
		<!--- if the folder doesn't exist, do nothing --->
		<cfif not directoryExists(arguments.beanPath)>
			<cfreturn />
		</cfif>
		<!--- get list of beans to load --->
		<cfdirectory action="list" directory="#arguments.beanPath#" filter="*.cfc" name="local.beanQuery" recurse="true" />
		<cfloop query="local.beanQuery">
			<cfset local.beanName = filePathToBeanName(local.beanQuery.directory, local.beanquery.name, arguments.resourcesBasePath) />
			<cfset local.beanPath = filePathToBeanPath(local.beanQuery.directory, local.beanquery.name, arguments.resourcesPath, arguments.resourcesBasePath) />
			<cftry>
				<cfset local.objBean = createObject("component", local.beanPath) />
				<cfif isInstanceOf(local.objBean, "taffy.core.baseRepresentation")>
					<cfset this.transients[local.beanName] = local.beanPath />
				<cfelse>
					<cfset this.beans[local.beanName] = local.objBean />
				</cfif>
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
		<cfargument name="resourcesPath" />
		<cfargument name="resourcesBasePath" />
		<cfset var beanPath = "" />
		<cfif len(resourcesBasePath) eq 0>
			<cfset arguments.resourcesBasePath = "!@$%^&*()" />
		</cfif>
		<cfset beanPath =
			resourcesPath
			&
			"."
			&
			replaceList(
				replace(path, resourcesBasePath, ""),
				"/,\",
				".,."
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
		<cfset beanPath = replace(beanPath, "..", ".", "ALL") />
		<cfif left(beanPath, 1) eq ".">
			<cfset beanPath = right(beanPath, len(beanPath)-1) />
		</cfif>
		<cfreturn beanPath />
	</cffunction>

	<cffunction name="filePathToBeanName" access="private">
		<cfargument name="path" />
		<cfargument name="filename" />
		<cfargument name="basepath" />
		<cfif len(basepath) eq 0>
			<cfset arguments.basePath = "!@$%^&*()" />
		</cfif>
		<cfreturn
			replaceList(
				replace(path, basepath, ""),
				"/,\",
				","
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
		<cfif structKeyExists(arguments.metaData, "properties") and isArray(arguments.metaData.properties)>
			<cfloop from="1" to="#arrayLen(arguments.metaData.properties)#" index="local.p">
				<cfset local.propName = arguments.metaData.properties[local.p].name />
				<cfif beanExists(local.propName)>
					<cfset local.bean = getBean(arguments.beanName) />
					<cfset local.bean[local.propName] = getBean(local.propName) />
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