<!DOCTYPE HTML>
<html>
<head>
	<title><cfoutput>#application._taffy.settings.docs.APIName# Documentation - #application._taffy.settings.docs.APIversion#</cfoutput></title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="icon" href="https://fav.farm/🍬" />
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
			<h1><cfoutput>#application._taffy.settings.docs.APIName#</cfoutput></h1>
			<span class="ver text-muted" style="left: 0">Version <cfoutput>#application._taffy.settings.docs.APIversion#</cfoutput></span>
		</div>

		<div class="row" id="resources">
			<h3>Resources:</h3>
			<div class="panel-group" id="resourcesAccordion">
				<cfoutput>
					<cfloop from="1" to="#arrayLen(application._taffy.uriMatchOrder)#" index="local.resource">
						<cfset local.currentResource = application._taffy.endpoints[application._taffy.uriMatchOrder[local.resource]] />
						<cfset local.bean = application._taffy.factory.getBean(local.currentResource.beanName) />
						<cfset local.beanMeta = getMetaData(local.bean) />
						<cfif structKeyExists(local.beanMeta, "taffy_docs_hide") OR structKeyExists(local.beanMeta, "taffy:docs:hide")>
							<cfscript>continue;</cfscript>
						</cfif>
						<div class="panel panel-default">
							<div class="panel-heading">
								<h4 class="panel-title">
									<a href="###local.currentResource.beanName#" class="accordion-toggle" data-toggle="collapse" data-parent="##resourcesAccordion">
										<cfif structKeyExists(local.beanMeta, "taffy:docs:name")>
											#local.beanMeta['taffy:docs:name']#
										<cfelseif structKeyExists(local.beanMeta, "taffy_docs_name")>
											#local.beanMeta['taffy_docs_name']#
										<cfelse>
											#local.currentResource.beanName#
										</cfif>
									</a>
									<cfloop list="DELETE|warning,PATCH|warning,PUT|warning,POST|danger,GET|primary" index="local.verb">
										<cfif structKeyExists(local.currentResource.methods, listFirst(local.verb,'|'))>
											<span class="verb label label-success">#ucase(listFirst(local.verb,'|'))#</span>
										</cfif>
									</cfloop>
									<code style="float:right; margin-top: -15px; display: inline-block;">#local.currentResource.srcUri#</code>
								</h4>
							</div>
							<div id="#local.currentResource.beanName#" class="in">
								<div class="panel-body resourceWrapper">
									<div class="col-md-12 docs">
										<cfset local.metadata = getMetaData(application._taffy.factory.getBean(local.currentResource.beanName)) />
										<cfset local.docData = getHintsFromMetadata(local.metadata) />
										<cfif structKeyExists(local.docData, 'hint')><div class="doc">#docData.hint#</div><hr/></cfif>
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
												<cfscript>continue;</cfscript><!--- this has to be script for CF8 compat --->
											</cfif>
											<cfset local.found[local.func.name] = true />
											<div class="col-md-12"><h5 class="verbHeading">#thisVerb#</h5></div>
											<cfif structKeyExists(local.func, "hint")>
												<div class="col-md-12 doc">#local.func.hint#</div>
											</cfif>
											<div class="inputs-wrapper">
												<!--- begin inputs panel --->
												<cfset inputsCount = 0 />
												<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
													<cfset local.param = local.func.parameters[local.p] />
													<cfif structKeyExists(local.param, "taffy_docs_hide") OR structKeyExists(local.param, "taffy:docs:hide")>
														<cfscript>continue;</cfscript>
													</cfif>
													<cfset inputsCount++ />
												</cfloop>
												<cfif inputsCount gt 0>
													<div class="panel panel-default">
														<div class="panel-heading">
															<h6 class="panel-title"><a href="###local.currentResource.beanName#_#local.func.name#_inputs" class="accordion-toggle" data-toggle="collapse" data-parent="###local.currentResource.beanName#_docs">Inputs</a></h6>
														</div>
														<div class="panel-collapse collapse" id="#local.currentResource.beanName#_#local.func.name#_inputs">
															<div class="panel-body">
																<cfloop from="1" to="#arrayLen(local.func.parameters)#" index="local.p">
																	<cfset local.param = local.func.parameters[local.p] />
																	<cfif structKeyExists(local.param, "taffy_docs_hide") OR structKeyExists(local.param, "taffy:docs:hide")>
																		<cfscript>continue;</cfscript>
																	</cfif>
																	<div class="row">
																		<div class="col-md-12">
																			<strong>#local.param.name#</strong>
																			<cfif not structKeyExists(local.param, 'required') or not local.param.required>
																				optional
																			<cfelse>
																				required
																			</cfif>
																			<cfif structKeyExists(local.param, "type")>
																				#local.param.type#
																			</cfif>
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
																				<br/><p class="doc hint">#local.param.hint#</p>
																			</cfif>
																		</div>
																	</div>
																</cfloop>
															</div>
														</div>
													</div>
												</cfif>
												<!--- end inputs panel --->
												<!--- begin sample response --->
												<cfset hasSample = false />
												<cfset sample = '' />
												<cfloop from="1" to="#arrayLen(local.beanMeta.functions)#" index="functionIndex">
													<cfif  local.beanMeta.functions[functionIndex].name eq 'sample#local.func.name#Response'>
														<cfset hasSample = true />
														<cfinvoke
															component="#local.bean#"
															method="sample#local.func.name#Response"
															argumentcollection={}
															returnvariable="sample"
														/>
														<cfbreak />
													</cfif>
												</cfloop>
												<cfif hasSample>
													<div class="row">
														<div class="col-md-12">
															<div class="panel panel-default">
																<div class="panel-heading">
																	<h6 class="panel-title">
																		<a href="###local.currentResource.beanName#_#local.func.name#_sample" class="accordion-toggle" data-toggle="collapse" data-parent="###local.currentResource.beanName#_docs">Sample Response</a>
																	</h6>
																</div>
																<div class="panel-collapse collapse" id="#local.currentResource.beanName#_#local.func.name#_sample">
																	<div class="panel-body">
																		<div class="col-md-12">
																			<script type="text/javascript" defer>
																				document.write("<pre><code>");
																				document.write(JSON.stringify(#serializeJson(sample)#, null, '  '));
																				document.write("</code></pre>");
																			</script>
																		</div>
																	</div>
																</div>
															</div>
														</div>
													</div>
												</cfif>
												<!--- end sample response --->
											</div>
										</cfloop>
									</div><!-- /col-md-6 (docs) -->
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
		});
	</script>
</body>
</html>
