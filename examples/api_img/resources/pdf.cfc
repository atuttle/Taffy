<cfcomponent extends="taffy.core.resource" taffy:uri="/pdf/mew">

	<cffunction name="get">
		<cfset var local = structNew() />
		<cfdocument format="PDF" name="local.pdf">
			<h1>Mew mew mew mew</h1>
			<img src="/taffy/examples/api_img/images/Kitten_cups.jpg"/><br/>
			<img src="/taffy/examples/api_img/images/PETA_sea_kitten.jpg" />
		</cfdocument>
		<cfreturn streamBinary(local.pdf).withStatus(200).withMime("application/pdf") />
	</cffunction>

</cfcomponent>