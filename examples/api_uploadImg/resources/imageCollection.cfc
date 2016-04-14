<cfcomponent extends="taffy.core.resource" taffy:uri="/images">

	<cffunction name="post">
		<cfargument name="img" />
		<cfargument name="name" />
		<cfset var local = StructNew() />

		<cffile
			action="upload"
			destination="#getTempDirectory()#"
			fileField="img"
			nameConflict="MakeUnique"
			result="local.uploadResult"
			/>

		<cfreturn representationOf( {args: arguments, result: local.uploadResult} ) />

	</cffunction>

</cfcomponent>
