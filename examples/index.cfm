<cfdirectory action="list" directory="#getDirectoryFromPath(expandPath(cgi.script_name))#" name="them" sort="type,name" />
<cfoutput>
<ul>
<cfloop query="them">
	<cfif NOT left(name, 1) eq '.' AND name NEQ 'WEB-INF' AND name NEQ 'Application.cfm' AND name NEQ 'Application.cfc' AND name NEQ 'index.cfm'>
		<li><a href="#name#<cfif type EQ 'dir'>/</cfif>">#name#<cfif type EQ 'dir'>/</cfif></a>
	</cfif>
</cfloop>
</ul>
</cfoutput>