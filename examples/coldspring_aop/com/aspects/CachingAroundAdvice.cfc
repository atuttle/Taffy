<cfcomponent displayname="ReturnFormatter" extends="coldspring.aop.MethodInterceptor" hint="" output="false">

	<cffunction name="invokeMethod" access="public" returntype="any">
    	<cfargument name="methodInvocation" type="coldspring.aop.MethodInvocation" required="false" />
		<cfscript>
			
			// Look at the cfc to determine if it's configured for caching
			local.stRequestMeta = getRequestMeta(
				metaData = GetMetaData(arguments.methodInvocation.getTarget()),
				verb = arguments.methodInvocation.getMethod().getMethodName(),
				args = arguments.methodInvocation.getArguments()
			);
			
			// If we were able to retrieve data from cache, simply return that data
			if (local.stRequestMeta["foundInCache"]) {
				return local.stRequestMeta["cacheData"];
			}
			else {
				
				// If data was not in cache, run the method.
				local.methodReturnData = arguments.methodInvocation.proceed();
				
				// Put the return data into cache.
				if (IsDefined("local.methodReturnData")) {
					cachePut(local.stRequestMeta["cacheKey"], local.methodReturnData, local.stRequestMeta["timeSpan"]);
					return local.methodReturnData;
				}	
			}
		</cfscript>
    </cffunction>



	<cffunction name="getRequestMeta" access="private" returntype="struct">
		<cfargument name="metaData" type="struct" required="true" />
		<cfargument name="verb" type="string" required="true" />
		<cfargument name="args" type="struct" required="true" />
		<cfscript>
			
			// Default variables
			local.stCacheSettings = StructNew();
			local.stCacheSettings["toCache"] = false;
			local.stCacheSettings["cacheKey"] = "";
			local.stCacheSettings["cacheTimeout"] = 0;
			local.stCacheSettings["foundInCache"] = false;
			local.stCacheSettings["cacheData"] = "";
			local.stCacheSettings["timeSpan"] = 0;
			local.stCacheSettings["requestURI"] = rebuildURI(
				taffyURI = arguments.metaData["taffy:uri"],
				args = arguments.args
			);
			
			// Using the meta data, determine the component caching defaults
			if (StructKeyExists(arguments.metaData,"taffy:cache")) {
				local.stCacheSettings["toCache"] = arguments.metaData["taffy:cache"];
			}
			else if (StructKeyExists(arguments.metaData,"taffy_cache")) {
				local.stCacheSettings["toCache"] = arguments.metaData["taffy_cache"];
			}
			
			if (StructKeyExists(arguments.metaData,"taffy:cachetimeout")) {
				local.stCacheSettings["cacheTimeout"] = arguments.metaData["taffy:cachetimeout"];
			}
			else if (StructKeyExists(arguments.metaData,"taffy_cachetimeout")) {
				local.stCacheSettings["cacheTimeout"] = arguments.metaData["taffy:cachetimeout"];
			}
			
			if (StructKeyExists(arguments.metaData,"taffy:cacheunit")) {
				local.stCacheSettings["unit"] = arguments.metaData["taffy:cacheunit"];
			}
			else if (StructKeyExists(arguments.metaData,"taffy_cacheunit")) {
				local.stCacheSettings["unit"] = arguments.metaData["taffy:_acheunit"];
			}
			else {
				local.stCacheSettings["unit"] = "minutes";
			}
			
			// Now we must look at the method level. First we need to loop over the functions
			// array and find our method.
			local.methods = arguments.metaData["functions"];
			for (local.i = 1; local.i LTE ArrayLen(local.methods); local.i++) {
				if (local.methods[i].name EQ arguments.verb) {
					local.activeMethod = local.methods[i];
					break;
				}
			}
			
			// Now that we know the method, look at its meta data to see if there are
			// overriding cache settings on the method level.
			if (StructKeyExists(local.activeMethod,"taffy:cache")) {
				local.stCacheSettings["toCache"] = local.activeMethod['taffy:cache'];
			}
			else if (StructKeyExists(local.activeMethod,"taffy_cache")) {
				local.stCacheSettings["toCache"] = local.activeMethod['taffy_cache'];
			}
			
			if (StructKeyExists(local.activeMethod,"taffy:cachetimeout")) {
				local.stCacheSettings["cacheTimeout"] = local.activeMethod["taffy:cachetimeout"];
			}
			else if (StructKeyExists(local.activeMethod,"taffy_cachetimeout")) {
				local.stCacheSettings["cacheTimeout"] = local.activeMethod["taffy_cachetimeout"];
			}
			
			if (StructKeyExists(local.activeMethod,"taffy:cacheunit")) {
				local.stCacheSettings["unit"] = local.activeMethod["taffy:cacheunit"];
			}
			else if (StructKeyExists(local.activeMethod,"taffy_cacheunit")) {
				local.stCacheSettings["unit"] = local.activeMethod["taffy_cacheunit"];
			}
			
			// Determine if we're doing any caching at all
			if (local.stCacheSettings["toCache"]) {
				
				// We are caching. Next step, build the unique cache key that represents
				// this specific request.
				local.stCacheSettings["cacheKey"] = buildRequestCacheKey(
					resource = arguments.metaData.fullname,
					verb = "get",
					args = arguments.args
				);
				
				// Look to see if the data is available in cache
				local.cacheData = cacheGet(local.stCacheSettings["cacheKey"]);
				if (IsDefined("local.cacheData")) {
					local.cacheMeta = CacheGetMetaData(local.stCacheSettings["cacheKey"]);
					local.stCacheSettings["foundInCache"] = true;
					local.stCacheSettings["cacheData"] = local.cacheData;
					local.stCacheSettings["cachedAt"] = local.cacheMeta["createdtime"];
				}

			}
			
			// Create the appropriate timespan
			if (local.stCacheSettings["unit"] EQ "days") {
				local.stCacheSettings["timeSpan"] = CreateTimeSpan(local.stCacheSettings["cacheTimeout"],0,0,0);
			}
			else if (local.stCacheSettings["unit"] EQ "hours") {
				local.stCacheSettings["timeSpan"] = CreateTimeSpan(0,local.stCacheSettings["cacheTimeout"],0,0);
			}
			else if (local.stCacheSettings["unit"] EQ "minutes") {
				local.stCacheSettings["timeSpan"] = CreateTimeSpan(0,0,local.stCacheSettings["cacheTimeout"],0);
			}
			else if (local.stCacheSettings["unit"] EQ "seconds") {
				local.stCacheSettings["timeSpan"] = CreateTimeSpan(0,0,0,local.stCacheSettings["cacheTimeout"]);
			}
			
			return local.stCacheSettings;
		</cfscript>
	</cffunction>
	
	
	<cffunction name="buildRequestCacheKey" access="private" output="no" returntype="string" hint="Builds a unique key by identifying the unique parts of a resource request.">
		<cfargument name="resource" type="string" required="true" />
		<cfargument name="verb" type="string" required="true" />
		<cfargument name="args" type="any" required="true" />
		<cfset local.key = arguments.resource & "_" & arguments.verb />
		<cfloop collection="#arguments.args#" item="local.argKey">
			<cfset local.key = local.key & "_" & local.argKey & ":" & arguments.args[local.argKey] />
		</cfloop>
		<cfreturn LCase(local.key) />
	</cffunction>
	
	
	<cffunction name="rebuildURI" access="private" returntype="string" hint="" output="no">
		<cfargument name="taffyURI" type="string" required="true" />
		<cfargument name="args" type="struct" required="true" />
		<cfscript>
			
			local.sRebuiltURL = arguments.taffyURI;
			local.nQueryParamCount = 0;
			
			// Loop over the arguments. Add to a pattern, search, replace, or append
			for (local.key IN arguments.args) {
				local.sPattern = "{#local.key#}";
				if (FindNoCase(local.sPattern, local.sRebuiltURL)) {
					// The current argument is a pattern match and should be replaced in the pattern format
					local.sRebuiltURL = ReplaceNoCase(local.sRebuiltURL, local.sPattern, StructFind(arguments.args, local.key));	
				}
				else {
					// This argument was not in the url path, so it needs to be appended to the url
					if (local.nQueryParamCount EQ 0) { local.sRebuiltURL &= "?"; }
					else { local.sRebuiltURL &= "&"; }
					local.sRebuiltURL &= "#local.key#=#StructFind(arguments.args, local.key)#";
					local.nQueryParamCount++;
				}
			}
			
			return LCase(local.sRebuiltURL);
			
		</cfscript>
	</cffunction>
	
</cfcomponent>