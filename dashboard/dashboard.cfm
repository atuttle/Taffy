<!DOCTYPE HTML>
<html>
<head>
	<title>Taffy Dashboard</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="stylesheet" type="text/css" media="screen" href="/taffy/dashboard/asset.cfm?a=dash.css" />
</head>
<body>
	<div class="container">

		<div class="masthead">
			<button id="reload" class="btn btn-info">Reload API Cache</button>
			<h1>API Dashboard</h1>
			<span class="ver text-muted">Taffy <cfoutput>#application._taffy.version#</cfoutput></span>
		</div>

		<div class="row" id="alerts">
			<cfif structKeyExists(application._taffy, "status")
					and structKeyExists(application._taffy.status, "skippedResources")
					and arrayLen(application._taffy.status.skippedResources) gt 0>
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.status.skippedResources)#" index="local.i">
						<cfset local.err = application._taffy.status.skippedResources[local.i] />
						<div class="alert alert-warning">
							<strong class="label label-warning"><cfoutput>#local.err.resource#</cfoutput></strong> contains a syntax error.
							<cfif structKeyExists(local.err.exception, 'tagContext')>
								<strong>Error on line #local.err.exception.tagcontext[1].line#:</strong>
							</cfif>
							<hr/>
							<code>
								<cfif structKeyExists(local.err.exception, 'message')>#local.err.exception.message#</cfif>
								<cfif structKeyExists(local.err.exception, 'detail')><br/><br/>#local.err.exception.detail#</cfif>
							</code>
							<hr/>
							<cfset local.stack_id = createUUID() />
							<a href="javascript:toggleStackTrace('#local.stack_id#');">Toggle Stack Trace</a>
							<br/>
							<div class="stackTrace" id="#local.stack_id#">
								<cfdump var="#local.err.exception.tagcontext#" />
							</div>
							Reload the API Cache after resolving this error.
						</div>
					</cfloop>
				</cfoutput>
			</cfif>
		</div>

		<div class="row" id="resources">
			<h3>Resources:</h3>
			<div class="panel-group" id="resourcesAccordion">
				<cfset local.resources = listSort(structKeyList(application._taffy.endpoints), 'textnocase') />
				<cfoutput>
					<cfloop list="#local.resources#" index="local.resource">
						<cfset local.currentResource = application._taffy.endpoints[local.resource] />
						<div class="panel panel-default">
							<div class="panel-heading">
								<h4 class="panel-title">
									<a href="###local.currentResource.beanName#" class="accordion-toggle" data-toggle="collapse" data-parent="##resourcesAccordion">
										#local.currentResource.beanName#
									</a>
									<cfloop list="DELETE|warning,PUT|warning,POST|danger,GET|primary" index="local.verb">
										<cfif structKeyExists(local.currentResource.methods, listFirst(local.verb,'|'))>
											<span class="verb label label-success">#ucase(listFirst(local.verb,'|'))#</span>
										<cfelse>
											<span class="verb label label-default">#ucase(listFirst(local.verb,'|'))#</span>
										</cfif>
									</cfloop>
								</h4>
							</div>
							<div class="panel-collapse collapse" id="#local.currentResource.beanName#">
								<div class="panel-body">
									<div class="col-md-6">
										<div class="well resource" data-uri="#local.currentResource.srcUri#">
											<button class="btn btn-primary submitRequest">Send</button>
											<select class="form-control input-sm reqMethod">
												<cfloop list="GET,POST,PUT,DELETE" index="local.verb">
													<cfif structKeyExists(local.currentResource.methods, local.verb)>
														<option value="#local.verb#">#local.verb#</option>
													</cfif>
												</cfloop>
											</select>
											<code>#local.currentResource.srcUri#</code>

											<h4>Accept:</h4>
											<select class="form-control input-sm reqFormat">
												<cfloop list="#structKeyList(application._taffy.settings.mimeTypes)#" index="local.mime">
													<option value="#local.mime#">#application._taffy.settings.mimeTypes[local.mime]#</option>
												</cfloop>
											</select>

											<cfif arrayLen(local.currentResource.tokens) gt 0>
												<div class="reqTokens">
													<h4>Path Tokens:</h4>
													<form class="form-horizontal">
														<cfloop from="1" to="#arrayLen(local.currentResource.tokens)#" index="local.token">
															<div class="form-group row">
																<div class="col-md-3">
																	<label for="token_#local.currentResource.beanName#_#local.currentResource.tokens[local.token]#">#local.currentResource.tokens[local.token]#:</label>
																</div>
																<div class="col-md-6">
																	<input id="token_#local.currentResource.beanName#_#local.currentResource.tokens[local.token]#" name="#local.currentResource.tokens[local.token]#" type="text" class="form-control input-sm" />
																</div>
															</div>
														</cfloop>
													</form>
												</div>
											</cfif>

											<div class="reqBody">
												<h4>Request Body:</h4>
												<textarea id="#local.currentResource.beanName#_RequestBody" class="form-control input-sm" rows="5"></textarea>
											</div>
											<div class="progress progress-striped active">
												<div class="progress-bar"  role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
													<span class="sr-only">Loading...</span>
												</div>
											</div>
											<div class="response">
												<hr />
												<h4>Response:</h4>
												<div class="responseHeaders"></div>
												<p class="responseTime"></p>
												<p class="label label-default responseStatus"></p>
												<pre><code class="responseBody"></code></pre>
											</div>
										</div><!-- /well (resource) -->
									</div><!-- /col-md-6 -->
									<div class="col-md-6">
										<cfset local.metadata = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
										<cfset local.docData = getHintsFromMetadata(local.metadata) />
										<cfif structKeyExists(local.docData, 'hint')><div class="doc">#docData.hint#</div><hr/></cfif>
										<cfset local.found = { get=false, post=false, put=false, delete=false } />
										<cfloop from="1" to="#arrayLen(local.docData.functions)#" index="local.f">
											<cfset local.func = local.docData.functions[local.f] />
											<cfset local.found[local.func.name] = true />
											<div class="col-md-12"><strong>#local.func.name#</strong></div>
											<cfif structKeyExists(local.func, "hint")>
												<div class="col-md-12 doc">#local.func.hint#</div>
											</cfif>
											<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
												<cfset local.param = local.func.parameters[local.p] />
												<div class="row">
 													<div class="col-md-11 col-md-offset-1">
															<cfif not structKeyExists(local.param, 'required') or not local.param.required>
																optional
															<cfelse>
																required
															</cfif>
															<cfif structKeyExists(local.param, "type")>
 																#local.param.type#
															</cfif>
															<strong>#local.param.name#</strong>
															<cfif structKeyExists(local.param, "default")>
																<cfif local.param.default eq "">
																	(default: "")
																<cfelse>
																	(default: #local.param.default#)
																</cfif>
															<cfelse>
																<!--- no default value --->
															</cfif>
														<cfif structKeyExists(param, "hint")>
															<br/><span class="doc">#local.param.hint#</span>
														</cfif>
 													</div>
												</div>
											</cfloop>
										</cfloop>
									</div><!-- /col-md-6 (docs) -->
								</div>
							</div>
						</div>
					</cfloop>
				</cfoutput>
			</div><!-- /panel-group -->
		</div><!-- /row -->

	</div><!-- /container -->

	<script src="/taffy/dashboard/asset.cfm?a=jquery.min.js"></script>
	<script src="/taffy/dashboard/asset.cfm?a=bootstrap.min.js"></script>
	<script src="/taffy/dashboard/asset.cfm?a=dash.js"></script>
	<script type="text/javascript">
		$(function(){
			var baseurl = '<cfoutput>#cgi.script_name#?dashboard</cfoutput>';
			$("#reload").click(function(){
				var reloadUrl = baseurl + '<cfoutput>&#application._taffy.settings.reloadKey#=#application._taffy.settings.reloadPassword#</cfoutput>';
				var btn = $("#reload");
				btn.html('Reloading...').attr('disabled','disabled');
				$.ajax({
					url: reloadUrl
					,type: 'GET'
					,cache: false
				}).done(function(data){
					//notify reload success
					$("#alerts").append('<div class="alert alert-success" id="reloadSuccess">API Cache Successfully Reloaded</div>');
					btn.removeAttr('disabled').html('Reload API Cache');
					setTimeout(function(){
						$("#reloadSuccess").fadeOut('fast', function(){
							$(this).remove();
						});
					}, 2000);
				}).fail(function(jqxhr, status, error){
					//notify reload fail
					$("#alerts").append('<div class="alert alert-danger" id="reloadFail">API Cache Reload Failed!</div>');
					btn.removeAttr('disabled').html('Reload API Cache');
					setTimeout(function(){
						$("#reloadFail").fadeOut('fast', function(){
							$(this).remove();
						});
					}, 2000);
				});
			});
		});
		function submitRequest( verb, resource, headers, body, callback ){
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

			if( body && body.indexOf('{') == 0 ){
				dType = "application/json";
			}

			var before = Date.now();

			$.ajax({
				type: verb
				,url: url
				,cache: false
				,headers: headers
				,data: body
				,contentType: dType
			}).done(function(data, status, xhr){
				var after = Date.now(), t = after-before;
				callback(
					t
					, xhr.status + " " + xhr.statusText		//status
					, xhr.getAllResponseHeaders()				//headers
					, xhr.responseText							//body
				);
			}).fail(function(xhr, status, err){
				var after = Date.now(), t = after-before;
				callback(
					t
					, xhr.status + " " + xhr.statusText		//status
					, xhr.getAllResponseHeaders()				//headers
					, xhr.responseText							//body
				);
			});
		}
	</script>
</body>
</html>