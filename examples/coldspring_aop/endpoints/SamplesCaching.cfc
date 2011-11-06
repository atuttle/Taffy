<cfcomponent extends="taffy.core.resource" taffy:aopbean="sampleWithCachingAdvice" taffy:uri="/aop/caching" taffy:cache="true" taffy:cachetimeout="10" taffy:cacheunit="seconds">

	<cffunction name="get" access="public" output="false" hint="">
		<cfscript>
			local.resourceData = StructNew();
			local.resourceData["foo"] = "bar";
			sleep(5000);
			return representationOf(local.resourceData).withStatus(200);
		</cfscript>
	</cffunction>

</cfcomponent>
