<cfset map = "/artist/{artistId}/art/{artId}" />
input: <tt><cfoutput>#map#</cfoutput></tt>


<cffunction name="convertURItoRegex">
	<cfargument name="uri" type="string" required="true" hint="wants the uri mapping defined by the cfc endpoint" />

	<cfset var almostTokens = rematch("{([^}]+)}", arguments.uri)/>
	<cfset var tokens = [] />
	<cfset var token = '' />

	<!--- extract token names and values from requested uri --->
	<cfset var uriRegex = arguments.uri />
	<cfloop array="#almostTokens#" index="token">
		<cfset arrayAppend(tokens, replaceList(token, "{,}", ",")) />
		<cfset uriRegex = rereplaceNoCase(uriRegex,"{[^}]+}", "([^\/]+)") />
	</cfloop>

	<cfreturn uriRegex />
</cffunction>



	<cfset uri = "/artist/47/art" />
	uri: <cfoutput>#uri#</cfoutput>

	<cfset groupMatches = refindNoSuck(map, uri) />
	<cfset arrayDeleteAt(groupMatches, 1) />


<cfscript>
	function reFindNoSuck(string pattern, string data, numeric startPos = 1){
		var sucky = refindNoCase(pattern, data, startPos, true);
		var i = 0;
		var awesome = [];
		if (isArray(sucky.len) and arrayLen(sucky.len) eq 0){return [];}
		for (i=1; i<= arrayLen(sucky.len); i++){
			arrayAppend( awesome, mid( data, sucky.pos[i], sucky.len[i]) );
		}
		return awesome;
	}
</cfscript>
