<cfcomponent extends="Taffy.core.resource" taffy_uri="/placekitten/{width}/{height}">

	<cfdirectory action="list" directory="#expandPath('./images')#" name="variables.images" />
	<cfset variables.fileTypes = { jpg="image/jpeg", jpeg="image/jpeg", gif="image/gif", png="image/png", bmp="image/bmp" } />

	<cffunction name="get" access="public" output="false">
		<cfargument name="width" />
		<cfargument name="height" />
		<cfset var img = '' />

		<!--- pick a file --->
		<cfset var row = randRange(1,variables.images.recordCount) />
		<cfset var file = variables.images.directory[row] & "/" & variables.images.name[row] />
		<cfset var fileType = listLast(variables.images.name[row], '.') />

		<!--- resize it on the fly to fit the requested dimensions, scaling as necessary --->
		<cfif arguments.width gt arguments.height>
			<cfimage action="resize" source="#file#" name="img" height="" width="#arguments.width#" />
			<cfset imageCrop(img, 0, 0, arguments.width, arguments.height) />
		<cfelseif arguments.width lt arguments.height>
			<cfimage action="resize" source="#file#" name="img" height="#arguments.height#" width="" />
			<cfset imageCrop(img, 0, 0, arguments.width, arguments.height) />
		<cfelse>
			<cfimage action="read" name="img" source="#file#" />
			<cfset w = imageGetWidth(img) />
			<cfset h = imageGetHeight(img) />
			<cfif w gt h>
				<cfimage action="resize" source="#file#" name="img" height="#arguments.height#" width="" />
			<cfelseif h gt w>
				<cfimage action="resize" source="#file#" name="img" height="" width="#arguments.width#" />
			<cfelse>
				<cfimage action="resize" source="#file#" name="img" height="#arguments.height#" width="#arguments.width#" />
			</cfif>
			<cfset imageCrop(img, 0, 0, arguments.width, arguments.height) />
		</cfif>

		<cfreturn streamImage(img).withStatus(200).withMime(fileTypes[fileType]) />

	</cffunction>

</cfcomponent>