<h1>Taffy Dashboard</h1>
<p><a href="<cfoutput>#cgi.script_name#?dashboard&#application._taffy.settings.reloadKey#=#application._taffy.settings.reloadPassword#</cfoutput>">Reload the API</a> - updates cached objects and uri mappings</p>

<cfdump var="#application._taffy#">
