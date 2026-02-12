<!DOCTYPE HTML>
<html>
<head>
	<title><cfoutput>#application._taffy.settings.docs.APIName# Documentation - #application._taffy.settings.docs.APIversion#</cfoutput></title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="icon" href="https://fav.farm/🍬" />
	<cfif application._taffy.settings.allowGoogleFonts>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:wght@400;500;600;700&family=Atkinson+Hyperlegible+Mono:wght@400;600;700&display=swap" rel="stylesheet">
	</cfif>
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
				<h1 class="dashboard-title"><cfoutput>#application._taffy.settings.docs.APIName#</cfoutput></h1>
				<span class="dashboard-version">Version <cfoutput>#application._taffy.settings.docs.APIversion#</cfoutput></span>
			</div>
		</header>

		<section id="resources">
			<h2 style="font-size: 1.25rem; font-weight: 600; margin: 0 0 1rem 0;">Resources:</h2>

			<div id="resourcesAccordion">
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.uriMatchOrder)#" index="local.resource">
						<cfset local.currentResource = application._taffy.endpoints[application._taffy.uriMatchOrder[local.resource]] />
						<cfset local.bean = application._taffy.factory.getBean(local.currentResource.beanName) />
						<cfset local.beanMeta = getMetaData(local.bean) />
						<cfif structKeyExists(local.beanMeta, "taffy_docs_hide") OR structKeyExists(local.beanMeta, "taffy:docs:hide")>
							<cfscript>continue;</cfscript>
						</cfif>
						<div class="resource-panel">
							<div class="resource-header" data-target="#local.currentResource.beanName#">
								<span class="resource-name">
									<cfif structKeyExists(local.beanMeta, "taffy:docs:name")>
										#local.beanMeta['taffy:docs:name']#
									<cfelseif structKeyExists(local.beanMeta, "taffy_docs_name")>
										#local.beanMeta['taffy_docs_name']#
									<cfelse>
										#local.currentResource.beanName#
									</cfif>
								</span>
								<span class="resource-meta">
									<code class="resource-uri">#local.currentResource.srcUri#</code>
									<cfloop list="GET,POST,PUT,PATCH,DELETE" index="local.verb">
										<cfif structKeyExists(local.currentResource.methods, local.verb)>
											<span class="verb verb-#lcase(local.verb)#">#local.verb#</span>
										</cfif>
									</cfloop>
								</span>
							</div>
							<div class="resource-content" id="#local.currentResource.beanName#">
								<cfset local.metadata = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
								<cfset local.docData = getHintsFromMetadata(local.metadata) />
								<cfif structKeyExists(local.docData, 'hint')>
									<p class="doc-hint">#local.docData.hint#</p>
								</cfif>
								<cfset local.found = { get=false, post=false, put=false, patch=false, delete=false } />
								<cfloop from="1" to="#arrayLen(local.docData.functions)#" index="local.f">
									<cfset local.func = local.docData.functions[local.f] />
									<cfset verbs = "GET,POST,PUT,PATCH,DELETE,OPTIONS,HEAD" />
									<cfset thisVerb = local.func.name />
									<cfif structKeyExists(local.func,"taffy_verb")>
										<cfset thisVerb = local.func.taffy_verb />
									<cfelseif structKeyExists(local.func,"taffy:verb")>
										<cfset thisVerb = local.func['taffy:verb'] />
									</cfif>
									<cfif listFindNoCase(verbs, thisVerb) eq 0
											OR structKeyExists(local.func, "taffy_docs_hide")
											OR structKeyExists(local.func, "taffy:docs:hide")>
										<cfscript>continue;</cfscript>
									</cfif>
									<cfset local.found[local.func.name] = true />
									<div class="doc-section">
										<h5 class="doc-verb-title">#thisVerb#</h5>
										<cfif structKeyExists(local.func, "hint")>
											<p class="doc-hint">#local.func.hint#</p>
										</cfif>
										<!--- begin inputs --->
										<cfset local.visibleParams = [] />
										<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
											<cfset local.param = local.func.parameters[local.p] />
											<cfif NOT (structKeyExists(local.param, "taffy_docs_hide") OR structKeyExists(local.param, "taffy:docs:hide"))>
												<cfset arrayAppend(local.visibleParams, local.param) />
											</cfif>
										</cfloop>
										<cfif arrayLen(local.visibleParams) gt 0>
											<div class="doc-accordion">
												<button type="button" class="doc-accordion-trigger" data-target="#local.currentResource.beanName#_#local.func.name#_inputs">
													Inputs
													<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
												</button>
												<div class="doc-accordion-content" id="#local.currentResource.beanName#_#local.func.name#_inputs">
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
										<!--- end inputs --->
										<!--- begin sample response --->
										<cfset hasSample = false />
										<cfset sample = '' />
										<cfloop from="1" to="#arrayLen(local.beanMeta.functions)#" index="functionIndex">
											<cfif local.beanMeta.functions[functionIndex].name eq 'sample#local.func.name#Response'>
												<cfset hasSample = true />
												<cfinvoke
													component="#local.bean#"
													method="#local.beanMeta.functions[functionIndex].name#"
													returnvariable="sample"
												/>
												<cfbreak />
											</cfif>
										</cfloop>
										<cfif hasSample>
											<div class="doc-accordion">
												<button type="button" class="doc-accordion-trigger" data-target="#local.currentResource.beanName#_#local.func.name#_sample">
													Sample Response
													<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
												</button>
												<div class="doc-accordion-content sample-response-content" id="#local.currentResource.beanName#_#local.func.name#_sample">
													<pre class="response-body"><code class="json-format">#serializeJson(sample)#</code></pre>
												</div>
											</div>
										</cfif>
										<!--- end sample response --->
									</div>
								</cfloop>
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
							<a href="https://github.com/atuttle/Taffy/wiki/So-you-want-to:-use-an-external-bean-factory-like-coldspring-to-completely-manage-resources"
							>Check out the wiki!</a>
						</p>
						<p>
							If all else fails, I recommend starting with <a href="https://github.com/atuttle/Taffy/wiki/Getting-Started">Getting Started</a>.
						</p>
					</div>
				</div>
			</cfif>

			<div class="alert alert-info mt-4">Resources are listed in matching order. From top to bottom, the first URI to match the request is used.</div>
		</section>

	</div>

	<script type="text/javascript">
		<cfinclude template="highlight.min.js" />

		document.addEventListener('DOMContentLoaded', function(){
			hljs.initHighlighting();

			// Resource header toggle
			document.querySelectorAll('.resource-header').forEach(function(header) {
				header.addEventListener('click', function() {
					var targetId = this.getAttribute('data-target');
					var content = document.getElementById(targetId);
					if (content) {
						content.classList.toggle('open');
					}
				});
			});

			// Doc accordion toggle
			document.querySelectorAll('.doc-accordion-trigger').forEach(function(trigger) {
				trigger.addEventListener('click', function() {
					var targetId = this.getAttribute('data-target');
					var content = document.getElementById(targetId);
					if (content) {
						this.classList.toggle('open');
						content.classList.toggle('open');
					}
				});
			});

			// Format JSON in sample responses
			document.querySelectorAll('.json-format').forEach(function(el) {
				try {
					var data = JSON.parse(el.textContent);
					el.textContent = JSON.stringify(data, null, '  ');
					hljs.highlightElement(el);
				} catch(e) {}
			});
		});
	</script>
</body>
</html>
