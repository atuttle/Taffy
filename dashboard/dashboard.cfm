<!DOCTYPE HTML>
<html>
<head>
	<title>Taffy Dashboard</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="icon" href="https://fav.farm/🍬" />
	<style>
		<cfinclude template="dashboard.css" />
		<cfinclude template="highlight-github.min.css" />
	</style>
</head>
<body>
	<script>
		window.taffy = { resources: {} };
	</script>

	<div style="max-width: 1200px; margin: 0 auto; padding: 1.5rem;">

		<header class="dashboard-header">
			<div>
				<h1 class="dashboard-title">API Dashboard</h1>
				<span class="dashboard-version">Taffy <cfoutput>#application._taffy.version#</cfoutput></span>
			</div>
			<div style="display: flex; gap: 0.5rem;">
				<button class="btn btn-secondary" data-modal-target="config">Config</button>
				<button class="btn btn-warning" id="reload">Reload API Cache</button>
				<button class="btn btn-success" id="docs" onclick="window.location.href = '<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>?docs'">Documentation</button>
			</div>
		</header>

		<!--- config modal --->
		<dialog id="config" class="modal" aria-labelledby="frameworkConfig">
			<div class="modal-header">
				<h3 class="modal-title" id="frameworkConfig">Framework Configuration</h3>
				<button type="button" class="modal-close" autofocus>&times;</button>
			</div>
			<div class="modal-body">
						<cfoutput>
							<table class="config-table">
								<tbody>
									<tr>
										<td>Reload on every request:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('reloadOnEveryRequest')#">?</a>
											#yesNoFormat(application._taffy.settings.reloadOnEveryRequest)#
										</td>
									</tr>
									<tr>
										<td>Return Exceptions as JSON:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('returnExceptionsAsJson')#">?</a>
											#yesNoFormat(application._taffy.settings.returnExceptionsAsJson)#
										</td>
									</tr>
									<tr>
										<td>CORS:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('allowCrossDomain')#">?</a>
											<cfif application._taffy.settings.allowCrossDomain EQ 'false'>No<cfelse>Yes</cfif>
										</td>
									</tr>
									<tr>
										<td>E-Tags:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('useEtags')#">?</a>
											#yesNoFormat(application._taffy.settings.useEtags)#
										</td>
									</tr>
									<tr>
										<td>JSONP:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('jsonp')#">?</a>
											<cfif application._taffy.settings.jsonp eq false>No<cfelse>?<strong>#application._taffy.settings.jsonp#=</strong>...</cfif>
										</td>
									</tr>
									<tr>
										<td>Endpoint URL Param:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('endpointURLParam')#">?</a>
											#application._taffy.settings.endpointURLParam#
										</td>
									</tr>
									<tr>
										<td>Serializer:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('serializer')#">?</a>
											#application._taffy.settings.serializer#
										</td>
									</tr>
									<tr>
										<td>Return Formats:</td>
										<td>
											<cfloop list="#structKeyList(application._taffy.settings.mimeTypes)#" index="local.m">
												#local.m#<cfif local.m NEQ listLast(structKeyList(application._taffy.settings.mimeTypes))>, </cfif>
											</cfloop>
										</td>
									</tr>
									<tr>
										<td>Global Headers:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('globalHeaders')#">?</a>
											<cfif structIsEmpty(application._taffy.settings.globalHeaders)>
												None
											<cfelse>
												<cfloop list="#structKeyList(application._taffy.settings.globalHeaders)#" index="local.h">
													<strong>#local.h#:</strong> #application._taffy.settings.globalHeaders[local.h]#<br/>
												</cfloop>
											</cfif>
										</td>
									</tr>
									<tr>
										<td>Exception Log Adapter:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('exceptionLogAdapter')#">?</a>
											#application._taffy.settings.exceptionLogAdapter#
										</td>
									</tr>
									<tr>
										<td>Exception Log Adapter Config:</td>
										<td>
											<a class="help-link" target="_blank" rel="noreferrer noopener" href="#getDocUrl('exceptionLogAdapterConfig')#">?</a>
											<cfif isSimpleValue(application._taffy.settings.exceptionLogAdapterConfig)>
												#application._taffy.settings.exceptionLogAdapterConfig#
											<cfelse>
												<cfloop list="#structKeyList(application._taffy.settings.exceptionLogAdapterConfig)#" index="local.k">
													<strong>#local.k#:</strong> #application._taffy.settings.exceptionLogAdapterConfig[local.k]#<br/>
												</cfloop>
											</cfif>
										</td>
									</tr>
									<tr>
										<td>Unhandled Paths:</td>
										<td>
											<cfloop list="#application._taffy.settings.unhandledPaths#" index="local.p">
												#local.p#<cfif local.p NEQ listLast(application._taffy.settings.unhandledPaths)>, </cfif>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</cfoutput>
			</div>
		</dialog>

		<!--- alerts --->
		<div id="alerts">
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
								<strong>#local.err.resource#</strong> contains a conflicting URI.
							<cfelseif local.errorcode EQ "taffy.resources.URIDoesntBeginWithForwardSlash">
								<strong>#local.err.resource#</strong> should have a URI that begins with a forward slash.
							<cfelse>
								<strong>#local.err.resource#</strong> contains a syntax error.
								<cfif structKeyExists(local.err.exception, 'tagContext')>
									<strong>Error on line #local.err.exception.tagcontext[1].line#:</strong>
								</cfif>
							</cfif>
							<hr style="border-color: inherit; opacity: 0.3; margin: 0.75rem 0;"/>
							<code style="display: block; padding: 0.5rem; background: rgba(0,0,0,0.05); border-radius: 0.25rem;">
								<cfif structKeyExists(local.err.exception, 'message')>#local.err.exception.message#</cfif>
								<cfif structKeyExists(local.err.exception, 'detail')><br/><br/>#local.err.exception.detail#</cfif>
							</code>
							<hr style="border-color: inherit; opacity: 0.3; margin: 0.75rem 0;"/>
							<cfset local.stack_id = createUUID() />
							<a href="javascript:toggleStackTrace('#local.stack_id#');" style="color: inherit;">Toggle Stack Trace</a>
							<div class="stackTrace" id="#local.stack_id#">
								<cfdump var="#local.err.exception.tagcontext#" />
							</div>
							<p style="margin-top: 0.5rem; font-size: 0.875rem;">Reload the API Cache after resolving this error.</p>
						</div>
					</cfloop>
				</cfoutput>
			</cfif>
		</div>

		<section id="resources">
			<div style="display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; margin-bottom: 1rem;">
				<h2 style="font-size: 1.25rem; font-weight: 600; margin: 0;">Resources:</h2>
				<input type="text" id="resourceSearch" placeholder="Filter... (ESC to clear)" autocomplete="off" class="form-input" style="flex: 1; max-width: 400px;" />
			</div>

			<div id="resourcesAccordion">
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.uriMatchOrder)#" index="local.resource">
						<cfset local.currentResource = application._taffy.endpoints[application._taffy.uriMatchOrder[local.resource]] />
						<cfset local.resourceHTTPID = rereplace(local.currentResource.beanName & "_" & hash(local.currentResource.srcURI), "[^0-9a-zA-Z_]", "_", "all") />
						<cfset local.bean = application._taffy.factory.getBean(local.currentResource.beanName) />
						<cfset local.md = getMetaData(local.bean) />
						<cfif structKeyExists(local.md, "taffy_dashboard_hide") OR structKeyExists(local.md, "taffy:dashboard:hide")>
							<cfscript>continue;</cfscript>
						</cfif>
						<div class="resource-panel">
							<div class="resource-header" data-target="#local.resourceHTTPID#">
								<span class="resource-name">
									<cfif structKeyExists(local.md, "taffy:dashboard:name")>
										#local.md['taffy:dashboard:name']#
									<cfelseif structKeyExists(local.md, "taffy_dashboard_name")>
										#local.md['taffy_dashboard_name']#
									<cfelseif structKeyExists(local.md, "taffy:docs:name")>
										#local.md['taffy:docs:name']#
									<cfelseif structKeyExists(local.md, "taffy_docs_name")>
										#local.md['taffy_docs_name']#
									<cfelse>
										#local.currentResource.beanName#
									</cfif>
								</span>
								<span class="resource-meta">
									<code class="resource-uri">#local.currentResource.srcUri#</code>
									<cfloop list="GET,POST,PUT,PATCH,DELETE" index="local.verb">
										<cfif structKeyExists(local.currentResource.methods, local.verb)>
											<span class="verb verb-#lcase(local.verb)#">#local.verb#</span>
										<cfelse>
											<span class="verb verb-disabled">#local.verb#</span>
										</cfif>
									</cfloop>
								</span>
							</div>
							<div class="resource-content" id="#local.resourceHTTPID#">
								<div class="tabs">
									<div class="tabs-nav">
										<button type="button" class="tab-btn active" data-tab="#local.resourceHTTPID#_run">Run it</button>
										<button type="button" class="tab-btn" data-tab="#local.resourceHTTPID#_docs">Documentation</button>
									</div>
									<div class="tab-pane active" id="#local.resourceHTTPID#_run">
										<div class="runner-form resource" data-uri="#local.currentResource.srcUri#" data-bean-name="#local.resourceHTTPID#">
											<div class="runner-row">
												<select class="form-select reqMethod">
													<cfloop list="GET,POST,PUT,PATCH,DELETE" index="local.verb">
														<cfif structKeyExists(local.currentResource.methods, local.verb)>
															<option value="#local.verb#">#local.verb#</option>
														</cfif>
													</cfloop>
													<cfif application._taffy.settings.allowCrossDomain NEQ 'false'>
														<option value="OPTIONS">OPTIONS</option>
													</cfif>
												</select>
												<input type="text" class="form-input runner-uri resourceUri" value="#local.currentResource.srcUri#" onclick="this.select()" />
												<button class="btn btn-primary submitRequest">Send</button>
												<button class="btn btn-ghost resetRequest">Reset</button>
											</div>

											<div class="toggles">
												<a class="expander" data-target="##qp_#local.resourceHTTPID#">+Query Params</a>
												<a class="expander" data-target="##accept_#local.resourceHTTPID#">+Accept</a>
												<a class="expander" data-target="##head_#local.resourceHTTPID#">+Headers</a>
												<a class="expander" data-target="##auth_#local.resourceHTTPID#">+Basic Auth</a>
											</div>

											<div class="expandable queryParams" id="qp_#local.resourceHTTPID#">
												<h4 class="section-title">Query String Parameters: <span class="section-subtitle">(optional)</span></h4>
												<div class="qparam">
													<input class="form-input paramName" placeholder="name" />
													<span class="text-muted">=</span>
													<input class="form-input paramValue" placeholder="value" />
													<button class="btn btn-ghost addParam" tabindex="-1">+</button>
												</div>
											</div>

											<div class="expandable" id="accept_#local.resourceHTTPID#">
												<h4 class="section-title">Accept:</h4>
												<select class="form-select reqFormat" style="width: 100%;">
													<cfloop list="#structKeyList(application._taffy.settings.mimeTypes)#" index="local.mime">
														<option value="#local.mime#"
															<cfif application._taffy.settings.defaultMime eq application._taffy.settings.mimeTypes[local.mime]>selected="selected"</cfif>
														>#application._taffy.settings.mimeTypes[local.mime]#</option>
													</cfloop>
												</select>
											</div>

											<cfif arrayLen(local.currentResource.tokens) gt 0>
												<div class="expandable open reqTokens">
													<h4 class="section-title">URI Tokens: <span class="section-subtitle">(required)</span></h4>
													<div class="tokenErrors" style="color: ##dc2626; font-size: 0.875rem; margin-bottom: 0.5rem;"></div>
													<form onsubmit="return false;">
														<cfloop from="1" to="#arrayLen(local.currentResource.tokens)#" index="local.token">
															<div class="token-row">
																<label class="token-label" for="token_#local.resourceHTTPID#_#local.currentResource.tokens[local.token]#">#local.currentResource.tokens[local.token]#:</label>
																<input id="token_#local.resourceHTTPID#_#local.currentResource.tokens[local.token]#" name="#local.currentResource.tokens[local.token]#" type="text" class="form-input token-input" />
															</div>
														</cfloop>
													</form>
												</div>
											</cfif>

											<div class="expandable reqHeaders" id="head_#local.resourceHTTPID#">
												<h4 class="section-title">Request Headers:</h4>
												<textarea
													rows="#listLen(structKeyList(application._taffy.settings.dashboardHeaders, '|'), '|')+1#"
													class="form-input requestHeaders"
													placeholder="X-MY-HEADER: VALUE"
													><cfloop list="#structKeyList(application._taffy.settings.dashboardHeaders, '|')#" delimiters="|" index="k">#k#: #application._taffy.settings.dashboardHeaders[k]##chr(13)##chr(10)#</cfloop></textarea>
											</div>

											<div class="expandable basicAuth" id="auth_#local.resourceHTTPID#">
												<h4 class="section-title">Basic Auth:</h4>
												<div class="auth-row">
													<input type="text" name="username" class="form-input" placeholder="Username" value="" />
													<input type="password" name="password" class="form-input" placeholder="Password" value="" />
												</div>
											</div>

											<div class="reqBody">
												<h4 class="section-title">Request Body:</h4>
												<textarea id="#local.resourceHTTPID#_RequestBody" class="form-input" rows="5"></textarea>
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
											<div class="progress">
												<div class="progress-bar"></div>
											</div>
											<div class="response">
												<h4 class="section-title">Response:</h4>
												<div class="response-headers"></div>
												<p class="response-time"></p>
												<span class="response-status"></span>
												<pre class="response-body"><code class="responseBody"></code></pre>
											</div>
										</div>
									</div>
									<div class="tab-pane" id="#local.resourceHTTPID#_docs">
										<cfset local.metadata = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
										<cfset local.docData = getHintsFromMetadata(local.metadata) />
										<cfif structKeyExists(local.docData, 'hint')>
											<p class="doc-hint">#local.docData.hint#</p>
										</cfif>
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
												<div class="doc-section">
													<h5 class="doc-verb-title">
														<cfif listFindNoCase('get,post,put,delete,patch',local.func.name)>
															#local.func.name#
														<cfelseif structKeyExists(local.func,'taffy_verb')>
															#local.func.taffy_verb#
														<cfelseif structKeyExists(local.func,'taffy:verb')>
															#local.func['taffy:verb']#
														</cfif>
													</h5>
													<cfif structKeyExists(local.func, "hint")>
														<p class="doc-hint">#local.func.hint#</p>
													</cfif>
													<cfset local.visibleParams = [] />
													<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
														<cfset local.param = local.func.parameters[local.p] />
														<cfif NOT (structKeyExists(local.param, "taffy_docs_hide") OR structKeyExists(local.param, "taffy:docs:hide") OR structKeyExists(local.param, "taffy_dashboard_hide") OR structKeyExists(local.param, "taffy:dashboard:hide"))>
															<cfset arrayAppend(local.visibleParams, local.param) />
														</cfif>
													</cfloop>
													<cfif arrayLen(local.visibleParams) gt 0>
														<div class="doc-accordion">
															<button type="button" class="doc-accordion-trigger" data-target="#local.resourceHTTPID#_#local.func.name#_inputs">
																Inputs
																<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
															</button>
															<div class="doc-accordion-content" id="#local.resourceHTTPID#_#local.func.name#_inputs">
																<cfloop array="#local.visibleParams#" index="local.param">
																	<div class="param-item">
																		<cfif not structKeyExists(local.param, 'required') or not local.param.required>
																			<span class="param-badge param-optional">optional</span>
																		<cfelse>
																			<span class="param-badge param-required">required</span>
																		</cfif>
																		<cfif structKeyExists(local.param, "type")>
																			<span class="param-type">#local.param.type#</span>
																		</cfif>
																		<span class="param-name">#local.param.name#</span>
																		<cfif structKeyExists(local.param, "default")>
																			<span class="param-default">
																				<cfif local.param.default eq "">(default: "")<cfelse>(default: #local.param.default#)</cfif>
																			</span>
																		</cfif>
																		<cfif structKeyExists(local.param, "hint")>
																			<p class="param-hint">#local.param.hint#</p>
																		</cfif>
																	</div>
																</cfloop>
															</div>
														</div>
													</cfif>
													<!--- begin sample response --->
													<cfset hasSample = false />
													<cfset sample = '' />
													<cfloop from="1" to="#arrayLen(local.md.functions)#" index="functionIndex">
														<cfif local.md.functions[functionIndex].name eq 'sample#local.func.name#Response'>
															<cfset hasSample = true />
															<cfinvoke
																component="#local.bean#"
																method="#local.md.functions[functionIndex].name#"
																returnvariable="sample"
															/>
															<cfbreak />
														</cfif>
													</cfloop>
													<cfif hasSample>
														<div class="doc-accordion">
															<button type="button" class="doc-accordion-trigger" data-target="#local.resourceHTTPID#_#local.func.name#_sample">
																Sample Response
																<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
															</button>
															<div class="doc-accordion-content sample-response-content" id="#local.resourceHTTPID#_#local.func.name#_sample">
																<pre class="response-body"><code class="json-format">#serializeJson(sample)#</code></pre>
															</div>
														</div>
													</cfif>
													<!--- end sample response --->
												</div>
											</cfif>
										</cfloop>
									</div>
								</div>
							</div>
						</div>
					</cfloop>
				</cfoutput>
			</div>

			<cfif arrayLen(application._taffy.uriMatchOrder) eq 0>
				<div class="empty-state">
					<div class="empty-state-header">Taffy is running but you haven't defined any resources yet.</div>
					<div class="empty-state-body">
						<p>
							It looks like you don't have any resources defined. Get started by creating the folder
							<code><cfoutput>#guessResourcesFullPath()#</cfoutput></code>, in which you should place your
							Resource CFC's.
						</p>
						<p>
							Or you could set up a bean factory, like <a href="http://www.coldspringframework.org/">ColdSpring</a>
							or <a href="https://github.com/seancorfield/di1">DI/1</a>. Want to know more about using bean factories with Taffy?
							<a href="https://github.com/atuttle/Taffy/wiki/So-you-want-to:-use-an-external-bean-factory-like-coldspring-to-completely-manage-resources">Check out the wiki!</a>
						</p>
						<p>
							If all else fails, I recommend starting with <a href="https://github.com/atuttle/Taffy/wiki/Getting-Started">Getting Started</a>.
						</p>
					</div>
				</div>
			</cfif>

			<cfif application._taffy.settings.reloadKey eq "reload" and application._taffy.settings.reloadPassword eq "true">
				<div class="alert alert-warning mt-4">
					<strong>Warning:</strong> Your reload key and password are using the framework default settings.
					It's advised that you <a target="_blank" rel="noreferrer noopener" href="<cfoutput>#getDocUrl('reloadKey')#</cfoutput>" style="color: inherit;">change these in production</a>.
				</div>
			</cfif>

			<div class="alert alert-info mt-4">
				Resources are listed in matching order. From top to bottom, the first URI to match the request is used.
			</div>
		</section>

	</div>

	<script type="text/javascript">
		<cfinclude template="jquery.min.js" />
		<cfinclude template="highlight.min.js" />
		<cfinclude template="dash.js" />

		$(function() {
			hljs.configure({ ignoreUnescapedHTML: true });

			// Format JSON in sample responses
			$('.json-format').each(function() {
				try {
					var json = JSON.parse($(this).text());
					$(this).text(JSON.stringify(json, null, 3));
				} catch(e) {}
			});

			hljs.highlightAll();

			// Modal handling (native dialog)
			$('[data-modal-target]').on('click', function() {
				var modalId = $(this).data('modal-target');
				document.getElementById(modalId).showModal();
			});

			$('.modal .modal-close').on('click', function() {
				$(this).closest('.modal')[0].close();
			});

			// Close modal on backdrop click
			$('.modal').on('click', function(e) {
				if (e.target === this) {
					this.close();
				}
			});

			// Resource accordion
			$('.resource-header').on('click', function() {
				var targetId = $(this).data('target');
				var $content = $('#' + targetId);
				var wasOpen = $content.hasClass('open');
				$content.toggleClass('open');

				// On open, show/hide request body based on method
				if (!wasOpen) {
					var resource = $content.find('.resource');
					var method = resource.find('.reqMethod option:checked').text();
					if (method === 'GET' || method === 'DELETE' || method === 'OPTIONS') {
						resource.find('.reqBody').hide();
						resource.find('.queryParams').addClass('active');
					} else {
						var args = window.taffy.resources[resource.data('beanName')];
						if (args && args[method.toLowerCase()]) {
							var ta = resource.find('.reqBody').show().find('textarea');
							ta.val(JSON.stringify(args[method.toLowerCase()], null, 3));
						} else {
							resource.find('.reqBody').show();
						}
						resource.find('.queryParams').removeClass('active');
					}
				}
			});

			// Doc accordion
			$('.doc-accordion-trigger').on('click', function() {
				var targetId = $(this).data('target');
				$('#' + targetId).toggleClass('open');
				$(this).toggleClass('open');
			});

			// Tab handling
			$('.tab-btn').on('click', function() {
				var $this = $(this);
				var $tabGroup = $this.closest('.tabs');
				var targetId = $this.data('tab');

				$tabGroup.find('.tab-btn').removeClass('active');
				$this.addClass('active');

				$tabGroup.find('.tab-pane').removeClass('active');
				$('#' + targetId).addClass('active');
			});

			// Reload button
			var baseurl = '<cfoutput>#cgi.script_name#?dashboard</cfoutput>';
			$('#reload').on('click', function() {
				var reloadUrl = baseurl + '<cfoutput>&#application._taffy.settings.reloadKey#=#application._taffy.settings.reloadPassword#</cfoutput>';
				var $btn = $(this);
				$btn.text('Reloading...').prop('disabled', true);

				$.get(reloadUrl)
					.done(function() {
						$('#alerts').append('<div id="reloadSuccess" class="alert alert-success">API Cache Successfully Reloaded. Refresh to see changes.</div>');
						$btn.prop('disabled', false).text('Reload API Cache');
						setTimeout(function() { $('#reloadSuccess').remove(); }, 2000);
					})
					.fail(function() {
						$('#alerts').append('<div id="reloadFail" class="alert alert-danger">API Cache Reload Failed!</div>');
						$btn.prop('disabled', false).text('Reload API Cache');
						setTimeout(function() { $('#reloadFail').remove(); }, 2000);
					});
			});
		});

		function submitRequest( verb, resource, headers, body, callback ){
			var url = window.location.protocol + '//' +  window.location.host;
			var endpointURLParam = '<cfoutput>#jsStringFormat(application._taffy.settings.endpointURLParam)#</cfoutput>';
			var endpoint = resource.split('?')[0];
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
				} catch (e) {}
			}

			var before = Date.now();

			$.ajax({
				type: verb,
				url: url,
				cache: false,
				headers: headers,
				data: body,
				contentType: dType
			}).always(function(a,b,c){
				var after = Date.now(), t = after-before;
				var xhr = (a && a.getAllResponseHeaders) ? a : c;
				callback(t, xhr.status + " " + xhr.statusText, xhr.getAllResponseHeaders(), xhr.responseText);
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
			var filter = $('#resourceSearch').val().toUpperCase();
			$('.resource-panel').each(function() {
				var text = $(this).find('.resource-name').text();
				$(this).toggle(text.toUpperCase().indexOf(filter) > -1);
			});
		}

		$('#resourceSearch').on('keyup', filterResources).on('keydown', function(e){
			if (e.keyCode == 27) { $(this).val(''); filterResources(); }
		});

		function toggleStackTrace(id) {
			$('#' + id).toggleClass('show');
		}
	</script>
</body>
</html>

<cffunction name="getDocUrl">
	<cfargument name="item" />
	<cfreturn "https://docs.taffy.io/##/#listFirst(application._taffy.version,'-')#?id=#lCase(item)#" />
</cffunction>
