<cfscript>
	function o(i){ writeOutput(i); }
	function verify(comp, verify_prop){
		try{
			obj = createObject("component", comp);
			if ( structKeyExists(obj, verify_prop) ){
				o("<h1>👍🏻 <code>#comp#</code> is in working order</h1>");
				return true;
			}else{
				o("<h1>🤔 <code>#comp#</code> is reachable but doesn't have the expected structure.</h1>");
				return false;
			}
		}catch(any e){
			o("<h2>❌ PROBLEM with <code>#comp#</code></h2>");
			o("<p>We're having trouble locating and verifying <code>taffy.core.api</code>. Click to expand the error below and try to resolve it.
				If you get stuck, the best place to ask for help is in the <a href=""https://cfml-slack.herokuapp.com/"">CFML Slack</a>,
				in the <strong>##taffy</strong> channel.</p>");
			writeDump(var: e, label: "ERROR for #comp#", expand: false);
			return false;
		}
	}
</cfscript>

<html>
	<head>
		<title>Taffy: Verify Install</title>
		<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" />

		<style>
			html {
				font-size: 16px;
			}
			body {
				font-family: Inter, sans-serif;
			}
			code {
				display: inline-block;
				background-color: #FFF0F5;
				color: #CD5C5C;
				padding: 0 7px;
				border-radius: 7px;
			}
			h1 {
				font-size: 2rem;
				font-weight: normal;
			}
			h1 code {
				font-size: 1.6rem;
			}
		</style>
	</head>
	<body>

		<div style="max-width: max-content; padding: 0 10px; margin: 0 auto;">
			<cfset app = verify("taffy.core.api", "noData") />
			<cfset factory = verify("taffy.core.factory", "loadBeansFromPath") />
			<cfset resource = verify("taffy.core.resource", "representationOf") />
			<cfset serializer = verify("taffy.core.nativeJsonSerializer", "getData") />
			<cfset deserializer = verify("taffy.core.baseDeserializer", "getFromForm") />

			<cfif app and resource and serializer and factory and serializer and deserializer>
				<h1><span style="font-size: 3rem">🍬</span> <strong>Taffy is correctly installed and ready to use!</strong></h1>
			</cfif>
		</div>

	</body>
</html>
