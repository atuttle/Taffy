<html>
<head>
	<title>Taffy Dashboard</title>
	<style type="text/css">
		<cfinclude template="dashboard.css" />
	</style>
</head>
<body>
<h1>Taffy Dashboard</h1>
<p id="toolbar">
	<button type="button" id="reloader">Reload API Cache</button>
	<button type="button" id="showDash" class="active">API Configuration</button>
	<button type="button" id="showMock">Mock Client</button>
</p>

<div id="dash">
	<h2>Resources:</h2>
	<table border="0">
		<tr>
			<th>Resource</th>
			<th>URI</th>
			<th>Methods</th>
		</tr>
		<cfoutput>
			<cfset variables.resources = listSort(structKeyList(application._taffy.endpoints), "textnocase") />
			<cfloop list="#variables.resources#" index="resource">
				<cfset currentResource = application._taffy.endpoints[resource] />
				<tr>
					<td>#currentResource.beanName#</td>
					<td>#currentResource.srcURI#</td>
					<td>#structKeyList(currentResource.methods, "|")#</td>
				</tr>
			</cfloop>
		</cfoutput>
	</table>

	<h3>Implemented Encodings:</h3>
	<ul>
		<cfoutput>
		<cfloop list="#structKeyList(application._taffy.settings.mimeExtensions)#" index="mime">
			<li>#mime# <cfif mime eq application._taffy.settings.defaultMime><em>(default)</em></cfif></li>
		</cfloop>
		</cfoutput>
	</ul>
</div>

<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>

<div id="mock">
	<cfinclude template="mocker.cfm"/>
</div>

<script type="text/javascript">
	$(function(){
		$("#reloader").click(function(){
			document.location.href = "<cfoutput>#cgi.script_name#?dashboard&#application._taffy.settings.reloadKey#=#application._taffy.settings.reloadPassword#</cfoutput>";
		});
		$("#resourcesList").click(function(e){
			$("#resourcesTable").toggle("slow");
		});
		$("#showDash").click(function(){
			$("#showMock").removeClass("active");
			$("#showDash").addClass("active");
			$("#mock").hide("fast");
			$("#dash").show("fast");
		});
		$("#showMock").click(function(){
			$("#showDash").removeClass("active");
			$("#showMock").addClass("active");
			$("#dash").hide("fast");
			$("#mock").show("fast");
		});
	});
</script>
</body>
</html>