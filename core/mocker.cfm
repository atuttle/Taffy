<div id="mocker_container">
	<div id="mocker">
		<p>
			<label>
				Resources:
				<cfif structKeyExists(application._taffy.settings, "mimeExtensions")>
					<cfset mimes = structKeyList(application._taffy.settings.mimeExtensions) />
					<cfset mimes = replaceNoCase(mimes, application._taffy.settings.defaultMime, "#application._taffy.settings.defaultMime#<em>*</em>" , "all")>
					<small><cfoutput>#mimes#</cfoutput></small>
				</cfif>
			</label>
			<select multiple="multiple" id="resources" size="5" class="bump">
				<cfoutput>
				<cfset variables.resources = listSort(structKeyList(application._taffy.endpoints), "textnocase") />
				<cfloop list="#variables.resources#" index="resource">
					<option value="#application._taffy.endpoints[resource].srcURI#">#application._taffy.endpoints[resource].srcURI#</option>
				</cfloop>
				</cfoutput>
			</select>
		</p>
		<p>
			<label for="uri">URI:</label>
			<input type="text" name="uri" id="uri" class="bump" />
			<button type="button" id="submit_get" title="Safe: Always safe to repeat" class="bump">GET</button>
			<button type="button" id="submit_put" title="Idempotent: Multiple requests have same effect as 1 request">PUT</button>
			<button type="button" id="submit_delete" title="Idempotent: Multiple requests have same effect as 1 request">DELETE</button>
			<button type="button" id="submit_post" title="Unsafe: Usually creates extra data if repeated">POST</button>
		</p>
		<div id="rest_body">
			<p>
				<label for="headers">Headers:</label>
				<textarea name="headers" id="headers" rows="7" cols="30" class="bump"></textarea>
			</p>
			<p>
				<label for="statuscode">Status:</label>
				<input type="text" name="statuscode" id="statuscode" class="bump" />
			</p>
			<p class="bump">
				<label for="content">Content:</label>
				<textarea rows="15" cols="83" name="content" id="content"></textarea>
			</p>
		</div>
	</div>
</div>

<script type="text/javascript">
	function submitRequest( verb, resource, representation ){
		var url = window.location.protocol + '//<cfoutput>#cgi.server_name#</cfoutput>';
		var endpointURLParam = '<cfoutput>#jsStringFormat(application._taffy.settings.endpointURLParam)#</cfoutput>';
		var endpoint = resource.split('?')[0];
		var args = '';
		var dType = null;

		if (window.location.port != 80){
			url += ':' + window.location.port;
		}
		url += '<cfoutput>#cgi.SCRIPT_NAME#</cfoutput>' + '?' + endpointURLParam + '=' + encodeURIComponent(endpoint);
		if( resource.indexOf('?') && resource.split('?')[1] ){
			url += '&' + resource.split('?')[1];
		}

		if( representation && representation.indexOf('{') == 0 ){
			dType = "application/json";
		}

		$("#rest_body").hide();
		$.ajax({
			type: verb,
			url: url,
			cache: false,
			data: representation,
			contentType: dType,
			success: function(data, status, xhr){
				$("#headers").val(xhr.getAllResponseHeaders());
				$("#statuscode").val(xhr.status + " " + xhr.statusText).removeClass("statusError").addClass("statusSuccess");
				$("#content").val(xhr.responseText);
				$("#rest_body").slideDown("fast");
			},
			error: function(xhr, status, err){
				$("#headers").val(xhr.getAllResponseHeaders());
				$("#statuscode").val(xhr.status + " " + xhr.statusText).removeClass("statusSuccess").addClass("statusError");
				$("#content").val(xhr.responseText);
				$("#rest_body").slideDown("fast");
			}
		});
	}
	$(function(){
		$("#resources").click(function(e){
			$("#uri").val(e.target.value);
		});
		$("#submit_get").click(function(){
			submitRequest("GET", $("#uri").val(), null);
		});
		$("#submit_put").click(function(){
			submitRequest("PUT", $("#uri").val(), $("#content").val());
		});
		$("#submit_delete").click(function(){
			submitRequest("DELETE", $("#uri").val(), null);
		});
		$("#submit_post").click(function(){
			submitRequest("POST", $("#uri").val(), $("#content").val());
		});
	});
</script>
