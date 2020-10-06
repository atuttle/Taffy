<!DOCTYPE HTML>
<html>
<head>
	<title>Taffy Dashboard</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<style>
		<cfinclude template="dash.css" />
		<cfinclude template="highlight-github.min.css" />
	</style>
</head>
<body>
	<script>
		window.taffy = { resources: {} };
	</script>

	<div class="container">

		<div class="masthead">
			<button id="docs" class="btn btn-success" onclick="window.location.href = '<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>?docs'">Documentation</button>
			<button id="reload" class="btn btn-info">Reload API Cache</button>
			<button data-toggle="modal" data-target="#config" class="btn btn-default">Config</button>
			<h1>API Dashboard</h1>
			<span class="ver text-muted">Taffy <cfoutput>#application._taffy.version#</cfoutput></span>
		</div>

		<!--- config modal --->
		<div class="modal fade" id="config" tabindex="-1" role="dialog" aria-labelledby="frameworkConfig" aria-hidden="true">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
						<h4 class="modal-title" id="frameworkConfig">Framework Configuration</h4>
					</div>
					<div class="modal-body" style="padding:0">
						<cfoutput>
							<div class="table-responsive">
								<table class="table table-striped" style="margin-bottom:0">
									<tr>
										<td><strong>Reload on every request:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('reloadOnEveryRequest')#</cfoutput>">?</a>
										#yesNoFormat(application._taffy.settings.reloadOnEveryRequest)#</td>
									</tr>
									<tr>
										<td><strong>Return Exceptions as JSON:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('returnExceptionsAsJson')#</cfoutput>">?</a>
										#yesNoFormat(application._taffy.settings.returnExceptionsAsJson)#</td>
									</tr>
									<tr>
										<td><strong>CORS:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('allowCrossDomain')#</cfoutput>">?</a>
										<cfif application._taffy.settings.allowCrossDomain EQ 'false'>No<cfelse>Yes</cfif></td>
									</tr>
									<tr>
										<td><strong>E-Tags:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('useEtags')#</cfoutput>">?</a>
										#yesNoFormat(application._taffy.settings.useEtags)#</td>
									</tr>
									<tr>
										<td><strong>JSONP:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('jsonp')#</cfoutput>">?</a>
										<cfif application._taffy.settings.jsonp eq false>No<cfelse>?<strong>#application._taffy.settings.jsonp#=</strong>...
										</cfif></td>
									</tr>
									<tr>
										<td><strong>Endpoint URL Param:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('endpointURLParam')#</cfoutput>">?</a>
										#application._taffy.settings.endpointURLParam#</td>
									</tr>
									<tr>
										<td><strong>Serializer:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('serializer')#</cfoutput>">?</a>
										#application._taffy.settings.serializer#</td>
									</tr>
									<tr>
										<td><strong>Return Formats:</strong></td>
										<td><ul>
											<cfloop list="#structKeyList(application._taffy.settings.mimeTypes)#" index="local.m">
												<li>#local.m#</li>
											</cfloop>
										</ul></td>
									</tr>
									<tr>
										<td><strong>Global Headers:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('globalHeaders')#</cfoutput>">?</a>
										<dl>
											<cfloop list="#structKeyList(application._taffy.settings.globalHeaders)#" index="local.h">
												<dt>#local.h#</dt>
												<dd>#application._taffy.settings.globalHeaders[local.h]#</dd>
											</cfloop>
										</dl>
										<cfif structIsEmpty(application._taffy.settings.globalHeaders)>
											None
										</cfif></td>
									</tr>
									<tr>
										<td><strong>Exception Log Adapter:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('exceptionLogAdapter')#</cfoutput>">?</a>
										#application._taffy.settings.exceptionLogAdapter#</td>
									</tr>
									<tr>
										<td><strong>Exception Log Adapter Config:</strong></td>
										<td><a class="label label-default" href="<cfoutput>#getDocUrl('exceptionLogAdapterConfig')#</cfoutput>">?</a>
										<cfif isSimpleValue(application._taffy.settings.exceptionLogAdapterConfig)>
											#application._taffy.settings.exceptionLogAdapterConfig#
										<cfelse>
											<dl>
												<cfloop list="#structKeyList(application._taffy.settings.exceptionLogAdapterConfig)#" index="local.k">
													<dt>#local.k#</dt>
													<dd>#application._taffy.settings.exceptionLogAdapterConfig[local.k]#</dd>
												</cfloop>
											</dl>
										</cfif></td>
									</tr>
									<tr>
										<td><strong>Unhandled Paths:</strong></td>
										<td><ul>
											<cfloop list="#application._taffy.settings.unhandledPaths#" index="local.p">
												<li>#local.p#</li>
											</cfloop>
										</ul></td>
									</tr>
								</table>
							</div>

						</cfoutput>
						<div class="clearfix"></div>
					</div>
				</div><!-- /.modal-content -->
			</div><!-- /.modal-dialog -->
		</div><!-- /.modal -->

		<!--- alerts --->
		<div class="row" id="alerts">
			<cfif structKeyExists(application._taffy, "status")
					and structKeyExists(application._taffy.status, "skippedResources")
					and arrayLen(application._taffy.status.skippedResources) gt 0>
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.status.skippedResources)#" index="local.i">

						<cfset local.err = application._taffy.status.skippedResources[local.i] />
						<cfset local.exceptionHasErrorCode = structKeyExists(local.err, "Exception") AND structKeyExists(local.err.Exception, "ErrorCode")>
						<cfset local.errorCode = "" />
						<cfif local.exceptionHasErrorCode>
							<cfset local.errorCode = local.err.Exception.ErrorCode>
						</cfif>

						<div class="alert alert-warning">
							<cfif local.errorCode EQ "taffy.resources.DuplicateUriPattern">
								<strong class="label label-warning"><cfoutput>#local.err.resource#</cfoutput></strong> contains a conflicting URI.
							<cfelseif local.errorcode EQ "taffy.resources.URIDoesntBeginWithForwardSlash">
								<strong class="label label-warning"><cfoutput>#local.err.resource#</cfoutput></strong> should have a URI that begins with a forward slash.
							<cfelse>
								<strong class="label label-warning"><cfoutput>#local.err.resource#</cfoutput></strong> contains a syntax error.
								<cfif structKeyExists(local.err.exception, 'tagContext')>
									<strong>Error on line #local.err.exception.tagcontext[1].line#:</strong>
								</cfif>
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
		</div><!-- /#alerts -->

		<div class="row" id="resources">
			<h3>
				Resources:
				<input type="text" id="resourceSearch" placeholder="Filter... (ESC to clear)" class="form-control" autocomplete="off" style="width:50%; display: inline-block;" />
			</h3>
			<div class="panel-group" id="resourcesAccordion">
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.uriMatchOrder)#" index="local.resource">
						<cfset local.currentResource = application._taffy.endpoints[application._taffy.uriMatchOrder[local.resource]] />
						<cfset local.resourceHTTPID = rereplace(local.currentResource.beanName & "_" & hash(local.currentResource.srcURI), "[^0-9a-zA-Z_]", "_", "all") />
						<cfset local.md = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
						<cfif structKeyExists(local.md, "taffy_dashboard_hide") OR structKeyExists(local.md, "taffy:dashboard:hide")>
							<cfscript>continue;</cfscript>
						</cfif>
						<div class="panel panel-default">
							<div class="panel-heading">
								<h4 class="panel-title">
									<a href="###local.resourceHTTPID#" class="accordion-toggle" data-toggle="collapse" data-parent="##resourcesAccordion">
										<code>#local.currentResource.srcUri#</code>
									</a>
									<cfloop list="DELETE|warning,PATCH|warning,PUT|warning,POST|danger,GET|primary" index="local.verb">
										<cfif structKeyExists(local.currentResource.methods, listFirst(local.verb,'|'))>
											<span class="verb label label-success">#ucase(listFirst(local.verb,'|'))#</span>
										<cfelse>
											<span class="verb label label-default">#ucase(listFirst(local.verb,'|'))#</span>
										</cfif>
									</cfloop>
								</h4>
							</div>
							<div class="panel-collapse collapse" id="#local.resourceHTTPID#">
								<div class="panel-body resourceWrapper">
									<div class="col-md-8 runner">
										<div class="well resource" data-uri="#local.currentResource.srcUri#" data-bean-name="#local.resourceHTTPID#">
											<button class="btn btn-primary submitRequest">Send</button>
											<button class="btn btn-success resetRequest">Reset</button>
											<button class="btn btn-default showDocs">Show Docs</button>
											<select class="form-control input-sm reqMethod">
												<cfloop list="GET,POST,PUT,PATCH,DELETE" index="local.verb">
													<cfif structKeyExists(local.currentResource.methods, local.verb)>
														<option value="#local.verb#">#local.verb#</option>
													</cfif>
												</cfloop>
												<cfif application._taffy.settings.allowCrossDomain NEQ 'false'>
													<option value="OPTIONS">OPTIONS</option>
												</cfif>
											</select>
											<input type="text" class="resourceUri form-control" value="#local.currentResource.srcUri#" onclick="this.select()" />
											<div class="toggles">
												<a class="expander" data-target="##qp_#local.resourceHTTPID#">+Query Params</a>
												&nbsp;<a class="expander" data-target="##accept_#local.resourceHTTPID#">+Accept</a>
												&nbsp;<a class="expander" data-target="##head_#local.resourceHTTPID#">+Headers</a>
												&nbsp;<a class="expander" data-target="##auth_#local.resourceHTTPID#">+Basic Auth</a>
											</div>

											<div class="queryParams expandable" id="qp_#local.resourceHTTPID#">
												<h4>Query String Parameters: <span class="text-muted">(optional)</span></h4>
												<div class="qparam row form-group">
													<div class="col-md-4">
														<input class="form-control input-small paramName" />
													</div>
													<div class="col-md-1 micro">=</div>
													<div class="col-md-4">
														<input class="form-control input-small paramValue" />
													</div>
													<div class="col-md-2">
														<button class="btn addParam" tabindex="-1">+</button>
													</div>
												</div>
											</div>

											<div class="expandable" id="accept_#local.resourceHTTPID#">
												<h4>Accept:</h4>
												<select class="form-control input-sm reqFormat">
													<cfloop list="#structKeyList(application._taffy.settings.mimeTypes)#" index="local.mime">
														<option value="#local.mime#"
															<cfif application._taffy.settings.defaultMime eq application._taffy.settings.mimeTypes[local.mime]>selected="selected"</cfif>
														>#application._taffy.settings.mimeTypes[local.mime]#</option>
													</cfloop>
												</select>
											</div>

											<cfif arrayLen(local.currentResource.tokens) gt 0>
												<div class="reqTokens">
													<h4>URI Tokens: <span class="text-muted">(required)</span></h4>
													<div class='tokenErrors'></div>
													<form class="form-horizontal" onsubmit="return false;">
														<cfloop from="1" to="#arrayLen(local.currentResource.tokens)#" index="local.token">
															<div class="form-group row">
																<div class="col-md-3">
																	<label class="control-label" for="token_#local.resourceHTTPID#_#local.currentResource.tokens[local.token]#">#local.currentResource.tokens[local.token]#:</label>
																</div>
																<div class="col-md-6">
																	<input id="token_#local.resourceHTTPID#_#local.currentResource.tokens[local.token]#" name="#local.currentResource.tokens[local.token]#" type="text" class="form-control input-sm" />
																</div>
															</div>
														</cfloop>
													</form>
												</div>
											</cfif>

											<div class="reqHeaders expandable" id="head_#local.resourceHTTPID#">
												<h4>Request Headers:</h4>
												<textarea
													rows="#listLen(structKeyList(application._taffy.settings.dashboardHeaders, '|'), '|')+1#"
													class="form-control input-sm requestHeaders"
													placeholder="X-MY-HEADER: VALUE"
													><cfloop list="#structKeyList(application._taffy.settings.dashboardHeaders, '|')#" delimiters="|" index="k">#k#: #application._taffy.settings.dashboardHeaders[k]##chr(13)##chr(10)#</cfloop></textarea>
											</div>

											<div class="expandable" id="auth_#local.resourceHTTPID#">
												<h4>Basic Auth:</h4>
												<div class="basicAuth row">
													<div class="col-md-6"><input type="text" name="username" class="form-control" placeholder="Username" value="" /></div>
													<div class="col-md-6"><input type="password" name="password" class="form-control" placeholder="Password" value="" /></div>
												</div>
											</div>

											<div class="reqBody">
												<h4>Request Body:</h4>
												<textarea id="#local.resourceHTTPID#_RequestBody" class="form-control input-sm" rows="5"></textarea>
												<cfif structKeyExists(local.md,"functions")>
													<cfset local.functions = local.md.functions />
												<cfelse>
													<cfset local.functions = arrayNew(1) />
												</cfif>

												<!--- only save body templates for POST & PUT --->
												<cfloop from="1" to="#arrayLen(local.functions)#" index="local.f">
													<cfif local.functions[local.f].name eq "POST" or local.functions[local.f].name eq "PUT" or local.functions[local.f].name eq "PATCH">
														<cfset local.args = {} />
														<!--- get a list of all function arguments --->
														<cfloop from="1" to="#arrayLen(local.functions[local.f].parameters)#" index="local.parm">
															<cfset local.paramAttributes = local.functions[local.f].parameters[local.parm]>
															<cfif structKeyExists(local.paramAttributes, "taffy_docs_hide") OR structKeyExists(local.paramAttributes, "taffy:docs:hide") OR structKeyExists(local.paramAttributes, "taffy_dashboard_hide") OR structKeyExists(local.paramAttributes, "taffy:dashboard:hide")>
																<cfscript>continue;</cfscript>
															</cfif>
															<cfif not structKeyExists(local.paramAttributes,"type")>
																<cfset local.args[local.paramAttributes.name] = '' />
															<cfelseif local.paramAttributes.type eq 'struct'>
																<cfset local.args[local.paramAttributes.name] = structNew() />
															<cfelseif local.paramAttributes.type eq 'array'>
																<cfset local.args[local.paramAttributes.name] = arrayNew(1) />
															<cfelseif local.paramAttributes.type eq 'numeric'>
																<cfset local.args[local.paramAttributes.name] = 0 />
															<cfelseif local.paramAttributes.type eq 'boolean'>
																<cfset local.args[local.paramAttributes.name] = true />
															<cfelse>
																<cfset local.args[local.paramAttributes.name] = '' />
															</cfif>
														</cfloop>
														<!--- omit uri tokens --->
														<cfloop from="1" to="#arrayLen(local.currentResource.tokens)#" index="local.token">
															<cfset structDelete(local.args, local.currentResource.tokens[local.token]) />
														</cfloop>
														<!--- save to page JS for runtime reference --->
														<script>
															taffy.resources['#local.resourceHTTPID#'] = taffy.resources['#local.resourceHTTPID#'] || {};
															taffy.resources['#local.resourceHTTPID#']['#lcase(local.functions[local.f].name)#'] = #serializeJson(local.args)#;
														</script>
													</cfif>
												</cfloop>
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
									</div><!-- /col-md-8 -->
									<div class="col-md-4 docs">
										<div class="row"><div class="col-md-12"><button class="btn btn-default hideDocs">Hide Docs</button></div></div>
										<strong><cfif structKeyExists(local.md, "taffy:docs:name")>
											#lcase(local.md['taffy:docs:name'])#
										<cfelseif structKeyExists(local.md, "taffy_docs_name")>
											#lcase(local.md['taffy_docs_name'])#
										<cfelse>
											#lcase(local.currentResource.beanName)#
										</cfif></strong><br />
										<cfset local.metadata = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
										<cfset local.docData = getHintsFromMetadata(local.metadata) />
										<cfif structKeyExists(local.docData, 'hint')><div class="doc">#local.docData.hint#</div><hr/></cfif>
										<cfset local.found = { get=false, post=false, put=false, patch=false, delete=false } />
										<cfloop from="1" to="#arrayLen(local.docData.functions)#" index="local.f">
											<cfset local.func = local.docData.functions[local.f] />
											<cfset local.found[local.func.name] = true />
											<!--- skip methods that are hidden --->
											<cfif structKeyExists(local.func, "taffy_docs_hide") OR structKeyExists(local.func, "taffy:docs:hide") OR structKeyExists(local.func, "taffy_dashboard_hide") OR structKeyExists(local.func, "taffy:dashboard:hide")>
												<cfscript>continue;</cfscript>
											</cfif>
											<!--- exclude methods that are not exposed as REST verbs --->
											<cfif listFindNoCase('get,post,put,delete,patch',local.func.name) OR structKeyExists(local.func,'taffy_verb') OR structKeyExists(local.func,'taffy:verb')>
	 											<div class="col-md-12"><strong>#local.func.name#</strong></div>
												<cfif structKeyExists(local.func, "hint")>
													<div class="col-md-12 doc">#local.func.hint#</div>
												</cfif>
												<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
													<cfset local.param = local.func.parameters[local.p] />
													<cfif structKeyExists(local.param, "taffy_docs_hide") OR structKeyExists(local.param, "taffy:docs:hide") OR structKeyExists(local.param, "taffy_dashboard_hide") OR structKeyExists(local.param, "taffy:dashboard:hide")>
														<cfscript>continue;</cfscript>
													</cfif>
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
															<cfif structKeyExists(local.param, "hint")>
																<br/><span class="doc">#local.param.hint#</span>
															</cfif>
														</div>
													</div>
												</cfloop>
											</cfif>
										</cfloop>
									</div><!-- /col-md-4 (docs) -->
								</div>
							</div>
						</div>
					</cfloop>
				</cfoutput>
			</div><!-- /panel-group -->
			<br />
			<cfif arrayLen(application._taffy.uriMatchOrder) eq 0>
				<div class="panel panel-warning">
					<div class="panel-heading">Taffy is running but you haven't defined any resources yet.</div>
					<div class="panel-body">
						<p>
							It looks like you don't have any resources defined. Get started by creating the folder
							<code><cfoutput>#guessResourcesFullPath()#</cfoutput></code>, in which you should place your
							Resource CFC's.
						</p>
						<p>
							Or you could set up a bean factory, like <a href="http://www.coldspringframework.org/">ColdSpring</a>
							or <a href="https://github.com/seancorfield/di1">DI/1</a>. Want to know more about using bean factories with Taffy?
							<a href="https://github.com/atuttle/Taffy/wiki/So-you-want-to:-use-an-external-bean-factory-like-coldspring-to-completely-manage-resources"
							>Check out the wiki!</a>
						</p>
						<p>
							If all else fails, I recommend starting with <a href="https://github.com/atuttle/Taffy/wiki/Getting-Started">Getting Started</a>.
						</p>
					</div>
				</div>
			</cfif>
			<cfif application._taffy.settings.reloadKey eq "reload" and application._taffy.settings.reloadPassword eq "true">
				<div class="alert alert-warning">
					<strong>Warning:</strong> Your reload key and password are using the framework default settings.
					It's advised that you <a href="<cfoutput>#getDocUrl('reloadKey')#</cfoutput>">change these in production</a>.
				</div>
			</cfif>
			<div class="alert alert-info">Resources are listed in matching order. From top to bottom, the first URI to match the request is used.</div>
		</div><!-- /#resources -->

	</div><!-- /container -->

	<script type="text/javascript">
		<cfinclude template="jquery.min.js" />
		<cfinclude template="bootstrap.min.js" />
		<cfinclude template="highlight.min.js" />
		<cfinclude template="dash.js" />

		$(function(){
			hljs.initHighlighting();

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
					$("#alerts").append('<div class="alert alert-success" id="reloadSuccess">API Cache Successfully Reloaded. Refresh to see changes.</div>');
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

			$(".hideDocs").on("click", function(){
				var docs = $(this).closest('.docs');
				var runner = $(this).closest('.resourceWrapper').find('.runner');
				docs.hide();
				runner.removeClass("col-md-8").addClass("col-md-12").find('.showDocs').show();
			});
			$(".showDocs").on("click", function(){
				var docs = $(this).closest('.resourceWrapper').find('.docs');
				var runner = $(this).closest('.runner');
				runner.removeClass("col-md-12").addClass("col-md-8");
				docs.show();
				$(this).hide();
			}).each(function(){
				$(this).click();
			});
		});
		function submitRequest( verb, resource, headers, body, callback ){
			var url = window.location.protocol + '//' +  window.location.host;
			var endpointURLParam = '<cfoutput>#jsStringFormat(application._taffy.settings.endpointURLParam)#</cfoutput>';
			var endpoint = resource.split('?')[0];
			var args = '';
			var dType = null;

			<cfif Len(application._taffy.settings.csrfToken.cookieName) AND Len(application._taffy.settings.csrfToken.headerName)>
				<cfif structKeyExists(GetFunctionList(), "encodeForJavascript")>
					<cfset local.csrfCookieName = encodeForJavascript(application._taffy.settings.csrfToken.cookieName)>
					<cfset local.csrfHeaderName = encodeForJavascript(application._taffy.settings.csrfToken.headerName)>
				<cfelse>
					<cfset local.csrfCookieName = jsStringFormat(application._taffy.settings.csrfToken.cookieName)>
					<cfset local.csrfHeaderName = jsStringFormat(application._taffy.settings.csrfToken.headerName)>
				</cfif>
				var csrfCookie = getCookie('<cfoutput>#local.csrfCookieName#</cfoutput>');
				if (csrfCookie) {
					headers['<cfoutput>#local.csrfHeaderName#</cfoutput>'] = csrfCookie;
				}
			</cfif>

			url += '<cfoutput>#cgi.SCRIPT_NAME#</cfoutput>' + '?' + endpointURLParam + '=' + encodeURIComponent(endpoint);
			if( resource.indexOf('?') && resource.split('?')[1] ){
				url += '&' + resource.split('?')[1];
			}

			if( body && typeof body === 'string' ){
				try {
					JSON.parse(body);
					dType = "application/json";
				} catch (e) {
					//Not a valid JSON string
				}
			}

			var before = Date.now();

			$.ajax({
				type: verb
				,url: url
				,cache: false
				,headers: headers
				,data: body
				,contentType: dType
			}).always(function(a,b,c){
				var after = Date.now(), t = after-before;
				var xhr = (a && a.getAllResponseHeaders) ? a : c;
				callback(
					t
					, xhr.status + " " + xhr.statusText		//status
					, xhr.getAllResponseHeaders()				//headers
					, xhr.responseText							//body
				);
			});
		}

		function getCookie(name) {
			var nameEQ = name + '=', ca = document.cookie.split(';'), i = 0, c;
				for(;i < ca.length;i++) {
					c = ca[i];
					while (c[0]==' ') c = c.substring(1);
					if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length);
				}
			return null;
		}
		function filterResources(){
			var input, filter, ul, li, a, i;
			input = document.getElementById('resourceSearch');
			filter = input.value.toUpperCase();
			ul = document.getElementById("resourcesAccordion");
			li = ul.getElementsByClassName('panel');
			for (i = 0; i < li.length; i++) {
				a = li[i].getElementsByTagName("a")[0];
				if (a.innerHTML.toUpperCase().indexOf(filter) > -1) {
					li[i].style.display = "";
				} else {
					li[i].style.display = "none";
				}
			}
		}
		function clearSearch(evt, input) {
			var code = evt.charCode || evt.keyCode;
			if (code == 27) { input.value = '';}
		}
		document.getElementById("resourceSearch").addEventListener("keyup", filterResources);
		document.getElementById("resourceSearch").addEventListener("keydown", function(e){
			clearSearch(e, this);
		});
	</script>
</body>
</html>

<cffunction name="getDocUrl">
	<cfargument name="item" />
	<cfreturn "http://docs.taffy.io/#listFirst(application._taffy.version,'-')#/##" & item />
</cffunction>
