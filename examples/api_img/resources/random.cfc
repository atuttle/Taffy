<cfcomponent extends="Taffy.core.resource" taffy_uri="/kitten/random">

	<cfdirectory action="list" directory="#expandPath('./images')#" name="variables.images" />
	<cfset variables.fileTypes = { jpg="image/jpeg", jpeg="image/jpeg", gif="image/gif", png="image/png", bmp="image/bmp" } />

	<cffunction name="get" access="public" output="false">
		<cfset var row = randRange(1,variables.images.recordCount) />
		<cfset var file = variables.images.directory[row] & "/" & variables.images.name[row] />
		<cfreturn streamFile(file).withStatus(200).withMime(fileTypes[listLast(variables.images.name[row], '.')]) />
	</cffunction>

</cfcomponent>