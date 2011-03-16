<cfcomponent extends="Taffy.core.resource" taffy_uri="/kitten/random">

	<cfdirectory action="list" directory="#expandPath('./images')#" name="variables.images" />

	<cffunction name="get" access="public" output="false">
		<cfset var row = randRange(1,variables.images.recordCount) />
		<cfset var file = variables.images.directory[row] & "/" & variables.images.name[row] />
		<cfreturn streamFile(file).withStatus(200).withMime('image/jpeg') />
	</cffunction>

</cfcomponent>