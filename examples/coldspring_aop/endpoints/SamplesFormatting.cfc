<cfcomponent extends="taffy.core.resource" taffy:uri="/aop/formatting" taffy:aopbean="sampleWithFormattingAdvice">

	<cffunction name="get" access="public" output="false" hint="">
		<cfscript>
			local.resourceData = StructNew();
			local.resourceData["foo"] = "bar";
			return local.resourceData;
		</cfscript>
	</cffunction>

</cfcomponent>
