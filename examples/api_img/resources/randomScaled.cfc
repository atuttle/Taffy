<cfcomponent extends="Taffy.core.resource" taffy_uri="/kitten/random/{width}/{height}">

	<cfdirectory action="list" directory="#expandPath('./images')#" name="variables.images" />
	<cfset variables.fileTypes = { jpg="image/jpeg", jpeg="image/jpeg", gif="image/gif", png="image/png", bmp="image/bmp" } />

	<cffunction name="get" access="public" output="false">
		<cfargument name="width" />
		<cfargument name="height" />
		<cfset var imageInfo = '' />
		<cfset var img = '' />

		<!--- pick a file --->
		<cfset var row = randRange(1,variables.images.recordCount) />
		<cfset var file = variables.images.directory[row] & "/" & variables.images.name[row] />
		<cfset var fileType = listLast(variables.images.name[row], '.') />

		<!--- resize it on the fly to fit the requested dimensions, scaling as necessary --->
		<cfimage action="info" source="#file#" structname="imageInfo" />
		<cfif imageInfo.height gt imageInfo.width>
			<cfimage action="resize" source="#file#" name="img" height="" width="#arguments.width#" />
			<cfset imageCrop(img, 0, 0, arguments.width, arguments.height) />
		<cfelse>
			<cfimage action="resize" source="#file#" name="img" height="#arguments.height#" width="" />
			<cfset imageCrop(img, 0, 0, arguments.width, arguments.height) />
		</cfif>

		<cfimage action="write" destination="ram://#arguments.width#_#arguments.height#.#fileType#" source="#img#" overwrite="yes" />

		<cfreturn streamFile("ram://#arguments.width#_#arguments.height#.#fileType#").withStatus(200).withMime(fileTypes[fileType]) />
	</cffunction>

</cfcomponent>