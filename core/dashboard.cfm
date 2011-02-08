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
	<button type="button" id="showDocs">API Documentation</button>
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

<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>

<div id="mock">
	<cfinclude template="mocker.cfm"/>
</div>
<div id="docs">
	<cfinclude template="docs.cfm" />
</div>

<script type="text/javascript">
	$(function(){
		var baseurl = '<cfoutput>#cgi.script_name#?dashboard</cfoutput>';
		$("#reloader").click(function(){
			document.location.href = baseurl + '<cfoutput>&#application._taffy.settings.reloadKey#=#application._taffy.settings.reloadPassword#</cfoutput>';
		});
		$("#exportPDF").click(function(){
			document.location.href = baseurl + '&exportPDF';
		});
		//save some selector refs for frequent use
		var m = $("#mock");
		var d = $("#dash");
		var o = $("#docs");
		var b = $("#toolbar button");
		$("#showDash").click(function(){
			b.removeClass("active");
			$(this).addClass("active");
			m.hide("fast");
			o.hide("fast");
			d.show("fast");
		});
		$("#showMock").click(function(){
			b.removeClass("active");
			$(this).addClass("active");
			d.hide("fast");
			o.hide("fast");
			m.show("fast");
		});
		$("#showDocs").click(function(){
			b.removeClass("active");
			$(this).addClass("active");
			m.hide("fast");
			d.hide("fast");
			o.show("fast");
		});
	});
</script>
</body>
</html>