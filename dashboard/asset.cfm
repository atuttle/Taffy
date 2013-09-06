<!---
	This script is used to proxy in static assets like JavaScript and CSS from the Taffy install folder without having to have them in the web root
	or to include their full contents in the html body, as Taffy 1.x did.
--->

<cfparam name="url.a" default="" />

<cfswitch expression="#url.a#">

	<cfcase value="jquery.min.js">
		<cfcontent type="text/javascript" file="#expandPath('./jquery.min.js')#" reset="true" /><cfabort />
	</cfcase>

	<cfcase value="bootstrap.min.js">
		<cfcontent type="text/javascript" file="#expandPath('./bootstrap.min.js')#" reset="true" /><cfabort />
	</cfcase>

	<cfcase value="dash.js">
		<cfcontent type="text/javascript" file="#expandPath('./dash.js')#" reset="true" /><cfabort />
	</cfcase>

	<cfcase value="dash.css">
		<cfcontent type="text/css" file="#expandPath('./dash.css')#" reset="true" /><cfabort />
	</cfcase>

	<cfcase value="loading.gif">
		<cfcontent type="image/gif" file="#expandPath('./loading.gif')#" reset="true" /><cfabort />
	</cfcase>

	<cfdefaultcase>
		<cfheader statuscode="404" statustext="Not Found" />
		<cfcontent reset="true" /><cfabort />
	</cfdefaultcase>

</cfswitch>
