<cfcomponent extends="taffy.core.resource" taffy:uri="/upload">

	<cffunction name="post">
		<cfargument name="img" />
		<cfset var local = structNew() />

		<!--- accept the upload --->
		<cffile action="upload" destination="#getTempDirectory()#" filefield="img" result="local.r" />

		<!--- delete the file --->
		<cffile action="delete" file="#local.r.serverdirectory#/#local.r.serverfile#" />

		<cfreturn representationOf( local.r ).withStatus(200) />

	</cffunction>

</cfcomponent>