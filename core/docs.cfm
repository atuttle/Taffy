<button type="button" id="exportPDF">Save as PDF</button>

<cfsavecontent variable="docContent">
	<cfloop list="#structKeyList(application._taffy.endpoints)#" index="e">
		<cfset resource = application._taffy.endpoints[e] />
		<cfset metadata = getMetaData(application._taffy.factory.getBean(resource.beanName)) />
		<cfset docData = getHintsFromMetaData(metadata) />
		<cfoutput>
	    	<table border="0">
	    		<thead>
					<tr>
						<td colspan="10">
							<strong>#resource.beanName#</strong><br/>
							<strong>URI:</strong> #docData.uri#
							<cfif structKeyExists(docdata, "hint")>
								<br/>
								<strong>Description:</strong> #docData.hint#
							</cfif>
						</td>
					</tr>
				</thead>
				<cfset found = StructNew() />
				<cfset found.GET = false />
				<cfset found.PUT = false />
				<cfset found.POST = false />
				<cfset found.DELETE = false />
				<cfloop from="1" to="#arrayLen(docData.functions)#" index="f">
					<cfset func = docData.functions[f] />
					<cfset found[func.name] = true />
					<tr>
						<td>#func.Name#</td>
						<td colspan="4"><cfif structKeyExists(func, "hint")>#func.hint#</cfif></td>
					</tr>
					<cfif arrayLen(func.parameters)>
						<tr>
							<td></td>
							<td><strong>Required</strong></td>
							<td><strong>Param</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Default</strong></td>
							<td><strong>Description</strong></td>
						</tr>
					</cfif>
					<cfloop from="1" to="#arrayLen(func.parameters)#" index="p">
						<cfset param = func.parameters[p] />
						<tr>
							<td></td>
							<td>
								<cfif not structKeyExists(param, 'required') or not param.required>
									<em>optional</em>
								<cfelse>
									<em>required</em>
								</cfif>
							</td>
							<td>
								<cfif structKeyExists(param, "type")>
									#param.type#
								</cfif>
							</td>
							<td>
								<strong>#param.name#</strong>
							</td>
							<td>
								<cfif structKeyExists(param, "default")>
									<cfif param.default eq "">
										[empty string]
									<cfelse>
										#param.default#
									</cfif>
								<cfelse>
									<!--- no default value --->
								</cfif>
							</td>
							<td>
								<cfif structKeyExists(param, "hint")>
									#param.hint#
								</cfif>
							</td>
						</tr>
					</cfloop>
				</cfloop>
				<cfloop list="#structKeyList(found)#" index="v">
					<cfif not found[v]>
						<tr>
							<td>#lcase(v)#</td>
							<td><strong>Not Allowed</strong></td>
						</tr>
					</cfif>
				</cfloop>
			</table>
	    </cfoutput>
	</cfloop>
</cfsavecontent>

<cfif structKeyExists(url, "exportPDF")>
	<cfdocument format="PDF" name="pdfContent" saveasname="API Documentation by Taffy.pdf">
		<cfoutput>#docContent#</cfoutput>
	</cfdocument>
	<cfcontent reset="true" type="application/pdf" variable="#pdfContent#" />
	<cfabort />
<cfelse>
	<!--- display docs on the page --->
	<cfoutput>#docContent#</cfoutput>
</cfif>
