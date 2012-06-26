<cfcomponent displayname="ReturnFormatter" extends="coldspring.aop.MethodInterceptor" hint="" output="false">
	
    <cffunction name="setTaffyResourceObject" access="public" returntype="any">
    	<cfargument name="taffyResourceObject" type="taffy.core.resource" required="true" />
        <cfset this.taffyResourceObject = arguments.taffyResourceObject />
    </cffunction>
    
	<cffunction name="invokeMethod" access="public" returntype="any">
    	<cfargument name="methodInvocation" type="coldspring.aop.MethodInvocation" required="false" />
		<cfscript>

			// Run the called method
			local.methodReturnData = arguments.methodInvocation.proceed();
			
			// Put the return data into a parent structre.
			if (IsDefined("local.methodReturnData")) {
				
				local.stReturnDataStructure = StructNew();
				local.stReturnDataStructure["request_timestamp"] = Now();
				local.stReturnDataStructure["data"] = local.methodReturnData;
				
				return this.taffyResourceObject.representationOf(local.stReturnDataStructure).withStatus(200);
				
			}
			
		</cfscript>
    </cffunction>
	
</cfcomponent>