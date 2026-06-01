component output="false" hint="Lightweight diagnostics for generated OpenAPI documents." {

	public struct function lint(required struct spec, struct context = {}) {
		if (!structKeyExists(arguments.context, "spec")) {
			arguments.context.spec = arguments.spec;
		}

		var issues = [];
		var state = {
			visitedPaths = {},
			localRefs = {},
			componentPaths = {},
			maxDepth = 50
		};

		lintComponentSchemas(arguments.spec, issues, arguments.context, state);
		lintPaths(arguments.spec, issues, arguments.context, state);
		addUnusedComponentIssues(arguments.spec, issues, arguments.context, state);
		sortIssues(issues);

		var summary = { errors = 0, warnings = 0, info = 0 };
		for (var i = 1; i <= arrayLen(issues); i++) {
			if (issues[i].severity == "error") summary.errors++;
			else if (issues[i].severity == "warning") summary.warnings++;
			else if (issues[i].severity == "info") summary.info++;
		}

		return {
			valid = summary.errors == 0,
			summary = summary,
			issues = issues
		};
	}

	private void function lintPaths(required struct spec, required array issues, required struct context, required struct state) {
		if (!structKeyExists(arguments.spec, "paths") || !isStruct(arguments.spec.paths)) {
			return;
		}

		var pathNames = sortedKeys(arguments.spec.paths);
		var validVerbs = "get,put,post,delete,options,head,patch,trace";
		for (var p = 1; p <= arrayLen(pathNames); p++) {
			var pathName = pathNames[p];
			var pathItem = arguments.spec.paths[pathName];
			if (!isStruct(pathItem)) continue;

			var tokens = extractPathTokens(pathName);
			var operationNames = sortedKeys(pathItem);
			for (var o = 1; o <= arrayLen(operationNames); o++) {
				var verb = lcase(operationNames[o]);
				if (!listFindNoCase(validVerbs, verb)) continue;
				if (!isStruct(pathItem[operationNames[o]])) continue;

				var operationPath = "/paths/" & pointerSegment(pathName) & "/" & pointerSegment(verb);
				lintOperation(
					pathName,
					verb,
					pathItem[operationNames[o]],
					operationPath,
					tokens,
					arguments.issues,
					arguments.context,
					arguments.state
				);
			}
		}
	}

	private void function lintOperation(
		required string pathName,
		required string verb,
		required struct operation,
		required string operationPath,
		required array tokens,
		required array issues,
		required struct context,
		required struct state
	) {
		if (!structKeyExists(arguments.operation, "operationId") || !isSimpleValue(arguments.operation.operationId) || !len(trim(arguments.operation.operationId))) {
			addIssue(
				arguments.issues,
				"warning",
				"operation.operationId.missing",
				arguments.operationPath & "/operationId",
				"Operation is missing an operationId.",
				"Add an operationId in the endpoint docs method or provider hook.",
				"",
				arguments.context
			);
		}

		var hasResponses = structKeyExists(arguments.operation, "responses") && isStruct(arguments.operation.responses);
		if (!hasResponses) {
			addIssue(
				arguments.issues,
				"error",
				"operation.responses.missing",
				arguments.operationPath & "/responses",
				"Operation has no responses object.",
				"Add responses in the endpoint docs method or provider response defaults.",
				"",
				arguments.context
			);
		} else if (structCount(arguments.operation.responses) == 1 && structKeyExists(arguments.operation.responses, "default")) {
			addIssue(
				arguments.issues,
				"warning",
				"operation.responses.onlyDefault",
				arguments.operationPath & "/responses",
				"Operation only documents a default response.",
				"Add documented success responses such as 200, 201, or 204.",
				"",
				arguments.context
			);
		}

		lintParameters(arguments.operation, arguments.operationPath, arguments.tokens, arguments.issues, arguments.context, arguments.state);
		lintRequestBody(arguments.operation, arguments.operationPath, arguments.issues, arguments.context, arguments.state);
		if (hasResponses) {
			lintResponses(arguments.operation.responses, arguments.operationPath, arguments.issues, arguments.context, arguments.state);
		}
	}

	private void function lintRequestBody(required struct operation, required string operationPath, required array issues, required struct context, required struct state) {
		if (!structKeyExists(arguments.operation, "requestBody")) {
			return;
		}

		var requestBodyPath = arguments.operationPath & "/requestBody";
		var requestBody = arguments.operation.requestBody;
		if (!isStruct(requestBody) || structKeyExists(requestBody, "$ref")) {
			return;
		}

		if (!structKeyExists(requestBody, "content") || !isStruct(requestBody.content)) {
			addIssue(
				arguments.issues,
				"error",
				"requestBody.content.missing",
				requestBodyPath & "/content",
				"Request body has no content object.",
				"Add requestBody.content in the endpoint docs method.",
				"request body",
				arguments.context
			);
			return;
		}

		var supportedContentTypes = buildRequestContentTypeLookup(arguments.context);
		var mediaTypes = sortedKeys(requestBody.content);
		for (var i = 1; i <= arrayLen(mediaTypes); i++) {
			var mediaType = mediaTypes[i];
			var mediaPath = requestBodyPath & "/content/" & pointerSegment(mediaType);
			var mediaObject = requestBody.content[mediaType];

			if (!structIsEmpty(supportedContentTypes) && !structKeyExists(supportedContentTypes, normalizeMediaType(mediaType))) {
				addIssue(
					arguments.issues,
					"warning",
					"requestBody.contentType.unsupported",
					mediaPath,
					"Request body content type " & mediaType & " is not supported by the configured deserializers.",
					"Use a configured request content type or add a matching deserializer.",
					"request body " & mediaType,
					arguments.context
				);
			}

			if (!isStruct(mediaObject) || !structKeyExists(mediaObject, "schema")) {
				addIssue(
					arguments.issues,
					"warning",
					"requestBody.schema.missing",
					mediaPath & "/schema",
					"Request body declares " & mediaType & " content without a schema.",
					"Add a schema or $ref in the endpoint docs method.",
					"request body " & mediaType,
					arguments.context
				);
			} else if (isStruct(mediaObject.schema)) {
				lintSchema(mediaObject.schema, mediaPath & "/schema", arguments.issues, arguments.context, arguments.state, 1, "", false);
			}
		}
	}

	private void function lintResponses(required struct responses, required string operationPath, required array issues, required struct context, required struct state) {
		var onlyDefault = structCount(arguments.responses) == 1 && structKeyExists(arguments.responses, "default");
		var supportedMediaTypes = buildResponseContentTypeLookup(arguments.context);
		var responseCodes = sortedKeys(arguments.responses);

		for (var r = 1; r <= arrayLen(responseCodes); r++) {
			var statusCode = responseCodes[r];
			var responsePath = arguments.operationPath & "/responses/" & pointerSegment(statusCode);
			var response = arguments.responses[statusCode];
			if (!isStruct(response) || structKeyExists(response, "$ref")) {
				continue;
			}

			var hasDescription = structKeyExists(response, "description") && isSimpleValue(response.description) && len(trim(response.description));
			if (!hasDescription) {
				addIssue(
					arguments.issues,
					"error",
					"response.description.missing",
					responsePath & "/description",
					"Response " & statusCode & " is missing a non-empty description.",
					"Add a response description in the endpoint docs method or provider response defaults.",
					"response " & statusCode,
					arguments.context
				);
			}

			var isUndocumentedDefault = lcase(statusCode) == "default" && hasDescription && response.description == "Response not documented.";
			if (isUndocumentedDefault && !onlyDefault) {
				addIssue(
					arguments.issues,
					"info",
					"response.default.undocumented",
					responsePath,
					"Default response is still marked as not documented.",
					"Add endpoint-specific response docs when this endpoint has a known contract.",
					"response default",
					arguments.context
				);
			}

			if (!structKeyExists(response, "content") || !isStruct(response.content)) {
				continue;
			}

			var mediaTypes = sortedKeys(response.content);
			for (var m = 1; m <= arrayLen(mediaTypes); m++) {
				var mediaType = mediaTypes[m];
				var mediaPath = responsePath & "/content/" & pointerSegment(mediaType);
				var mediaObject = response.content[mediaType];

				if (!structIsEmpty(supportedMediaTypes) && !structKeyExists(supportedMediaTypes, normalizeMediaType(mediaType))) {
					addIssue(
						arguments.issues,
						"warning",
						"response.contentType.unsupported",
						mediaPath,
						"Response content type " & mediaType & " is not one of the configured serializer MIME types.",
						"Use a configured response MIME type or add a matching serializer.",
						"response " & statusCode & " " & mediaType,
						arguments.context
					);
				}

				if (!isStruct(mediaObject) || !structKeyExists(mediaObject, "schema")) {
					addIssue(
						arguments.issues,
						"warning",
						"response.content.schema.missing",
						mediaPath & "/schema",
						"Response " & statusCode & " declares " & mediaType & " content without a schema.",
						"Add a schema or $ref in the endpoint docs method.",
						"response " & statusCode & " " & mediaType,
						arguments.context
					);
				} else if (isStruct(mediaObject.schema)) {
					lintSchema(mediaObject.schema, mediaPath & "/schema", arguments.issues, arguments.context, arguments.state, 1, "", isUndocumentedDefault);
				}
			}
		}
	}

	private void function lintParameters(required struct operation, required string operationPath, required array tokens, required array issues, required struct context, required struct state) {
		if (!structKeyExists(arguments.operation, "parameters") || !isArray(arguments.operation.parameters)) {
			reportMissingPathParameters(arguments.tokens, {}, arguments.operationPath, arguments.issues, arguments.context);
			return;
		}

		var seen = {};
		var pathParameters = {};
		var undeclaredPathTokens = getUndeclaredPathTokenLookup(arguments.operationPath, arguments.context);
		for (var i = 1; i <= arrayLen(arguments.operation.parameters); i++) {
			var parameterPath = arguments.operationPath & "/parameters/" & (i - 1);
			var parameter = arguments.operation.parameters[i];
			if (!isStruct(parameter) || structKeyExists(parameter, "$ref")) {
				continue;
			}

			var paramName = structKeyExists(parameter, "name") && isSimpleValue(parameter.name) ? parameter.name : "";
			var paramLocation = structKeyExists(parameter, "in") && isSimpleValue(parameter["in"]) ? parameter["in"] : "";
			var key = lcase(paramLocation) & "|" & lcase(paramName);

			if (len(paramName) && len(paramLocation)) {
				if (structKeyExists(seen, key)) {
					addIssue(
						arguments.issues,
						"error",
						"parameter.duplicate",
						parameterPath,
						"Parameter " & paramName & " appears more than once with the same location and name.",
						"Keep only one parameter for each location and name.",
						"parameter " & paramLocation & " " & paramName,
						arguments.context
					);
				}
				seen[key] = true;
			}

			if (lcase(paramLocation) == "path") {
				pathParameters[lcase(paramName)] = true;
				if (!structKeyExists(parameter, "required") || parameter.required != true) {
					addIssue(
						arguments.issues,
						"error",
						"parameter.path.requiredFalse",
						parameterPath & "/required",
						"Path parameter " & paramName & " must have required=true.",
						"Set required=true for path parameters.",
						"parameter path " & paramName,
						arguments.context
					);
				}

				if (structKeyExists(undeclaredPathTokens, lcase(paramName))) {
					addIssue(
						arguments.issues,
						"warning",
						"path.token.undeclaredHandler",
						parameterPath,
						"This URI token is not declared by the handler. Docs auto-generated. If the URI token is ignored/not-needed consider moving the handler to a better resource URI.",
						"",
						"parameter path " & paramName,
						arguments.context
					);
				}
			}

			if (!structKeyExists(parameter, "schema") && !structKeyExists(parameter, "content") && !structKeyExists(parameter, "$ref")) {
				addIssue(
					arguments.issues,
					"warning",
					"parameter.schema.missing",
					parameterPath & "/schema",
					"Parameter " & paramName & " has no schema, content, or $ref.",
					"Add a schema, content object, or $ref for the parameter.",
					"parameter " & paramLocation & " " & paramName,
					arguments.context
				);
			} else if (structKeyExists(parameter, "schema") && isStruct(parameter.schema)) {
				lintSchema(parameter.schema, parameterPath & "/schema", arguments.issues, arguments.context, arguments.state, 1, "", false);
			}
		}

		reportMissingPathParameters(arguments.tokens, pathParameters, arguments.operationPath, arguments.issues, arguments.context);
	}

	private void function reportMissingPathParameters(required array tokens, required struct pathParameters, required string operationPath, required array issues, required struct context) {
		for (var i = 1; i <= arrayLen(arguments.tokens); i++) {
			var token = arguments.tokens[i];
			if (!structKeyExists(arguments.pathParameters, lcase(token))) {
				addIssue(
					arguments.issues,
					"error",
					"path.parameter.missing",
					arguments.operationPath & "/parameters",
					"Path token " & token & " has no matching path parameter by name.",
					"Add a required path parameter named " & token & ".",
					"parameter path " & token,
					arguments.context
				);
			}
		}
	}

	private void function lintComponentSchemas(required struct spec, required array issues, required struct context, required struct state) {
		if (
			!structKeyExists(arguments.spec, "components")
			|| !isStruct(arguments.spec.components)
			|| !structKeyExists(arguments.spec.components, "schemas")
			|| !isStruct(arguments.spec.components.schemas)
		) {
			return;
		}

		var componentNames = sortedKeys(arguments.spec.components.schemas);
		for (var i = 1; i <= arrayLen(componentNames); i++) {
			var componentName = componentNames[i];
			var componentPath = "/components/schemas/" & pointerSegment(componentName);
			arguments.state.componentPaths[componentName] = componentPath;

			if (!len(componentName) || !reFindNoCase("^[A-Z0-9_.-]+$", componentName)) {
				addIssue(
					arguments.issues,
					"warning",
					"schema.component.nameSuspicious",
					componentPath,
					"Component schema name " & componentName & " may be awkward to use in $ref values.",
					"Use only letters, numbers, underscore, dot, and dash in component schema names.",
					"",
					arguments.context
				);
			}

			if (!isStruct(arguments.spec.components.schemas[componentName])) {
				addIssue(
					arguments.issues,
					"error",
					"schema.component.invalid",
					componentPath,
					"Component schema " & componentName & " is not a schema object.",
					"Replace the component value with a valid OpenAPI schema object.",
					"",
					arguments.context
				);
				continue;
			}

			lintSchema(arguments.spec.components.schemas[componentName], componentPath, arguments.issues, arguments.context, arguments.state, 1, componentName, false);
		}
	}

	private void function addUnusedComponentIssues(required struct spec, required array issues, required struct context, required struct state) {
		var componentNames = sortedKeys(arguments.state.componentPaths);
		for (var i = 1; i <= arrayLen(componentNames); i++) {
			var componentName = componentNames[i];
			var componentPath = arguments.state.componentPaths[componentName];
			if (structKeyExists(arguments.spec.components.schemas, componentName) && isStruct(arguments.spec.components.schemas[componentName]) && !structKeyExists(arguments.state.localRefs, componentPath)) {
				addIssue(
					arguments.issues,
					"info",
					"schema.component.unused",
					componentPath,
					"Component schema " & componentName & " is not referenced by a local $ref.",
					"Remove it if it is not intentionally published for reuse.",
					"",
					arguments.context
				);
			}
		}
	}

	private void function lintSchema(
		required any schema,
		required string path,
		required array issues,
		required struct context,
		required struct state,
		required numeric depth,
		string componentName = "",
		boolean skipEmptySchema = false
	) {
		if (arguments.depth > arguments.state.maxDepth) {
			addIssue(
				arguments.issues,
				"warning",
				"schema.traversal.maxDepth",
				arguments.path,
				"Schema traversal exceeded max depth.",
				"Simplify the schema nesting or replace deep inline schemas with component $ref values.",
				"",
				arguments.context
			);
			return;
		}

		if (!isStruct(arguments.schema)) {
			addIssue(
				arguments.issues,
				"error",
				"schema.properties.invalid",
				arguments.path,
				describeSchemaSubject(arguments.path, arguments.componentName) & " must be a schema object.",
				"Replace it with a valid OpenAPI schema object.",
				"",
				arguments.context
			);
			return;
		}

		if (structKeyExists(arguments.state.visitedPaths, arguments.path)) {
			return;
		}
		arguments.state.visitedPaths[arguments.path] = true;

		if (structKeyExists(arguments.schema, "$ref")) {
			lintRef(arguments.schema["$ref"], arguments.path & "/$ref", arguments.issues, arguments.context, arguments.state);
			return;
		}

		if (structIsEmpty(arguments.schema)) {
			if (!arguments.skipEmptySchema) {
				addIssue(
					arguments.issues,
					"warning",
					"schema.empty",
					arguments.path,
					describeSchemaSubject(arguments.path, arguments.componentName) & " is empty.",
					"Add a schema type, $ref, properties, items, or composition.",
					"",
					arguments.context
				);
			}
			return;
		}

		if (!hasSchemaTypeSignal(arguments.schema)) {
			addIssue(
				arguments.issues,
				"warning",
				"schema.type.missing",
				arguments.path,
				describeSchemaSubject(arguments.path, arguments.componentName) & " is missing a schema type or $ref and may be ambiguous.",
				"Add type, $ref, enum, const, or composition keywords when this schema has a known shape.",
				"",
				arguments.context
			);
		}

		if (schemaTypeIs(arguments.schema, "array") && !structKeyExists(arguments.schema, "items")) {
			addIssue(
				arguments.issues,
				"warning",
				"schema.array.itemsMissing",
				arguments.path & "/items",
				describeSchemaSubject(arguments.path, arguments.componentName) & " has type=array but no items schema.",
				"Add an items schema.",
				"",
				arguments.context
			);
		}

		if (structKeyExists(arguments.schema, "properties") && !isStruct(arguments.schema.properties)) {
			addIssue(
				arguments.issues,
				"error",
				"schema.properties.invalid",
				arguments.path & "/properties",
				describeSchemaSubject(arguments.path, arguments.componentName) & " has a properties value that is not a struct.",
				"Replace properties with a struct of property schemas.",
				"",
				arguments.context
			);
		}

		lintRequiredProperties(arguments.schema, arguments.path, arguments.issues, arguments.context, arguments.componentName);
		lintNestedSchemas(arguments.schema, arguments.path, arguments.issues, arguments.context, arguments.state, arguments.depth, arguments.componentName);
	}

	private void function lintRef(required any refValue, required string path, required array issues, required struct context, required struct state) {
		if (!isSimpleValue(arguments.refValue) || !len(trim(arguments.refValue))) {
			return;
		}

		var ref = normalizeRef(arguments.refValue);
		if (left(ref, 2) == chr(35) & "/") {
			var targetPath = mid(ref, 2, len(ref) - 1);
			arguments.state.localRefs[targetPath] = true;
			if (!pointerPathExists(arguments.context, targetPath)) {
				addIssue(
					arguments.issues,
					"error",
					"schema.ref.broken",
					arguments.path,
					"Schema $ref " & ref & " points to a target that does not exist.",
					"Update the $ref or add the missing schema target.",
					"",
					arguments.context
				);
			}
		} else {
			addIssue(
				arguments.issues,
				"info",
				"schema.ref.external",
				arguments.path,
				"External schema $ref " & ref & " is not checked by this linter.",
				"Use an OpenAPI validator that can resolve external references when you need full validation.",
				"",
				arguments.context
			);
		}
	}

	private boolean function pointerPathExists(required struct context, required string targetPath) {
		if (!structKeyExists(arguments.context, "spec") || !isStruct(arguments.context.spec)) {
			return false;
		}

		var current = arguments.context.spec;
		var parts = listToArray(arguments.targetPath, "/");
		for (var i = 1; i <= arrayLen(parts); i++) {
			var segment = unescapePointerSegment(parts[i]);
			if (isStruct(current) && structKeyExists(current, segment)) {
				current = current[segment];
			} else if (isArray(current) && isNumeric(segment) && val(segment) + 1 >= 1 && val(segment) + 1 <= arrayLen(current)) {
				current = current[val(segment) + 1];
			} else {
				return false;
			}
		}

		return true;
	}

	private void function lintRequiredProperties(required struct schema, required string path, required array issues, required struct context, required string componentName) {
		if (!structKeyExists(arguments.schema, "required") || !isArray(arguments.schema.required)) {
			return;
		}

		var hasProperties = structKeyExists(arguments.schema, "properties") && isStruct(arguments.schema.properties);
		for (var i = 1; i <= arrayLen(arguments.schema.required); i++) {
			if (!isSimpleValue(arguments.schema.required[i])) continue;
			var propertyName = arguments.schema.required[i];
			if (!hasProperties || !structKeyExists(arguments.schema.properties, propertyName)) {
				addIssue(
					arguments.issues,
					"error",
					"schema.object.requiredPropertyMissing",
					arguments.path & "/required/" & (i - 1),
					describeRequiredSubject(arguments.componentName) & " marks " & propertyName & " as required, but " & propertyName & " is not defined in properties.",
					"Add properties." & propertyName & " or remove it from required.",
					"",
					arguments.context
				);
			}
		}
	}

	private void function lintNestedSchemas(required struct schema, required string path, required array issues, required struct context, required struct state, required numeric depth, required string componentName) {
		if (structKeyExists(arguments.schema, "properties") && isStruct(arguments.schema.properties)) {
			var propertyNames = sortedKeys(arguments.schema.properties);
			for (var i = 1; i <= arrayLen(propertyNames); i++) {
				var propertyName = propertyNames[i];
				var propertyPath = arguments.path & "/properties/" & pointerSegment(propertyName);
				if (!isStruct(arguments.schema.properties[propertyName])) {
					addIssue(
						arguments.issues,
						"error",
						"schema.properties.invalid",
						propertyPath,
						describeSchemaSubject(propertyPath, arguments.componentName) & " must be a schema object.",
						"Replace it with a valid OpenAPI schema object.",
						"",
						arguments.context
					);
				} else {
					lintSchema(arguments.schema.properties[propertyName], propertyPath, arguments.issues, arguments.context, arguments.state, arguments.depth + 1, arguments.componentName, false);
				}
			}
		}

		if (structKeyExists(arguments.schema, "items") && isStruct(arguments.schema.items)) {
			lintSchema(arguments.schema.items, arguments.path & "/items", arguments.issues, arguments.context, arguments.state, arguments.depth + 1, arguments.componentName, false);
		}

		var compositionKeys = [ "oneOf", "anyOf", "allOf" ];
		for (var c = 1; c <= arrayLen(compositionKeys); c++) {
			var key = compositionKeys[c];
			if (!structKeyExists(arguments.schema, key) || !isArray(arguments.schema[key])) continue;
			for (var i2 = 1; i2 <= arrayLen(arguments.schema[key]); i2++) {
				if (isStruct(arguments.schema[key][i2])) {
					lintSchema(arguments.schema[key][i2], arguments.path & "/" & key & "/" & (i2 - 1), arguments.issues, arguments.context, arguments.state, arguments.depth + 1, arguments.componentName, false);
				}
			}
		}

		if (structKeyExists(arguments.schema, "not") && isStruct(arguments.schema.not)) {
			lintSchema(arguments.schema.not, arguments.path & "/not", arguments.issues, arguments.context, arguments.state, arguments.depth + 1, arguments.componentName, false);
		}
	}

	private void function addIssue(
		required array issues,
		required string severity,
		required string code,
		required string path,
		required string message,
		string suggestion = "",
		string target = "",
		struct context = {}
	) {
		var issue = {
			severity = arguments.severity,
			code = arguments.code,
			path = arguments.path,
			message = arguments.message
		};
		if (len(arguments.suggestion)) {
			issue.suggestion = arguments.suggestion;
		}

		var location = lookupLocation(arguments.path, arguments.context);
		if (!structIsEmpty(location)) {
			if (len(arguments.target)) {
				location.target = arguments.target;
			}
			issue.location = location;
		}

		arrayAppend(arguments.issues, issue);
	}

	private struct function getUndeclaredPathTokenLookup(required string operationPath, required struct context) {
		var out = {};
		var location = lookupSourceMapEntry(arguments.operationPath, arguments.context);
		if (!structKeyExists(location, "undeclaredPathTokens") || !isArray(location.undeclaredPathTokens)) {
			return out;
		}

		for (var i = 1; i <= arrayLen(location.undeclaredPathTokens); i++) {
			var token = location.undeclaredPathTokens[i];
			if (isSimpleValue(token) && len(trim(token))) {
				out[lcase(token)] = true;
			}
		}

		return out;
	}

	private struct function lookupLocation(required string path, required struct context) {
		var location = lookupSourceMapEntry(arguments.path, arguments.context);
		if (!structIsEmpty(location)) {
			structDelete(location, "undeclaredPathTokens");
		}

		return location;
	}

	private struct function lookupSourceMapEntry(required string path, required struct context) {
		if (!structKeyExists(arguments.context, "sourceMap") || !isStruct(arguments.context.sourceMap)) {
			return {};
		}

		var bestKey = "";
		for (var key in arguments.context.sourceMap) {
			if (left(arguments.path, len(key)) == key && len(key) > len(bestKey)) {
				bestKey = key;
			}
		}

		if (!len(bestKey) || !isStruct(arguments.context.sourceMap[bestKey])) {
			return {};
		}
		return duplicate(arguments.context.sourceMap[bestKey]);
	}

	private string function pointerSegment(required string value) {
		var out = replace(arguments.value, "~", "~0", "all");
		out = replace(out, "/", "~1", "all");
		return out;
	}

	private string function unescapePointerSegment(required string value) {
		var out = replace(arguments.value, "~1", "/", "all");
		out = replace(out, "~0", "~", "all");
		return out;
	}

	private array function extractPathTokens(required string pathName) {
		var tokens = [];
		var startAt = find("{", arguments.pathName);
		while (startAt > 0) {
			var endAt = find("}", arguments.pathName, startAt + 1);
			if (endAt <= startAt) break;
			arrayAppend(tokens, mid(arguments.pathName, startAt + 1, endAt - startAt - 1));
			startAt = find("{", arguments.pathName, endAt + 1);
		}
		return tokens;
	}

	private string function normalizeMediaType(required string mediaType) {
		return lcase(trim(listFirst(arguments.mediaType, ";")));
	}

	private struct function buildRequestContentTypeLookup(required struct context) {
		var out = {};
		if (!structKeyExists(arguments.context, "contentTypes") || !isStruct(arguments.context.contentTypes)) {
			return out;
		}
		for (var contentType in arguments.context.contentTypes) {
			out[normalizeMediaType(contentType)] = true;
		}
		return out;
	}

	private struct function buildResponseContentTypeLookup(required struct context) {
		var out = {};
		if (!structKeyExists(arguments.context, "settings") || !isStruct(arguments.context.settings)) {
			return out;
		}

		if (structKeyExists(arguments.context.settings, "mimeTypes") && isStruct(arguments.context.settings.mimeTypes)) {
			for (var mediaType in arguments.context.settings.mimeTypes) {
				out[normalizeMediaType(mediaType)] = true;
			}
		}

		if (structKeyExists(arguments.context.settings, "mimeExtensions") && isStruct(arguments.context.settings.mimeExtensions)) {
			for (var ext in arguments.context.settings.mimeExtensions) {
				out[normalizeMediaType(arguments.context.settings.mimeExtensions[ext])] = true;
			}
		}

		return out;
	}

	private boolean function hasSchemaTypeSignal(required struct schema) {
		if (structKeyExists(arguments.schema, "type")) {
			if (!isSimpleValue(arguments.schema.type)) return true;
			return len(trim(arguments.schema.type)) > 0;
		}

		var keys = [ "$ref", "oneOf", "anyOf", "allOf", "not", "enum", "const" ];
		for (var i = 1; i <= arrayLen(keys); i++) {
			if (structKeyExists(arguments.schema, keys[i])) {
				return true;
			}
		}

		return false;
	}

	private boolean function schemaTypeIs(required struct schema, required string typeName) {
		if (!structKeyExists(arguments.schema, "type")) {
			return false;
		}
		if (isSimpleValue(arguments.schema.type)) {
			return lcase(trim(arguments.schema.type)) == lcase(arguments.typeName);
		}
		if (isArray(arguments.schema.type)) {
			for (var i = 1; i <= arrayLen(arguments.schema.type); i++) {
				if (isSimpleValue(arguments.schema.type[i]) && lcase(trim(arguments.schema.type[i])) == lcase(arguments.typeName)) {
					return true;
				}
			}
		}
		return false;
	}

	private string function normalizeRef(required string ref) {
		if (left(arguments.ref, 3) == chr(35) & chr(35) & "/") {
			return right(arguments.ref, len(arguments.ref) - 1);
		}
		return arguments.ref;
	}

	private string function describeSchemaSubject(required string path, string componentName = "") {
		if (len(arguments.componentName)) {
			if (find("/properties/", arguments.path)) {
				return "Component schema " & arguments.componentName & "." & propertyPathSuffix(arguments.path);
			}
			return "Component schema " & arguments.componentName;
		}
		return "Schema";
	}

	private string function describeRequiredSubject(string componentName = "") {
		if (len(arguments.componentName)) {
			return "Component schema " & arguments.componentName;
		}
		return "Object schema";
	}

	private string function propertyPathSuffix(required string path) {
		var marker = "/properties/";
		var startAt = find(marker, arguments.path);
		if (!startAt) return "";
		var suffix = mid(arguments.path, startAt + len(marker), len(arguments.path));
		suffix = replace(suffix, "/properties/", ".", "all");
		suffix = replace(suffix, "/", ".", "all");

		var parts = listToArray(suffix, ".");
		for (var i = 1; i <= arrayLen(parts); i++) {
			parts[i] = unescapePointerSegment(parts[i]);
		}
		return arrayToList(parts, ".");
	}

	private array function sortedKeys(required struct input) {
		var keys = structKeyArray(arguments.input);
		arraySort(keys, "textnocase");
		return keys;
	}

	private void function sortIssues(required array issues) {
		for (var i = 1; i < arrayLen(arguments.issues); i++) {
			for (var j = i + 1; j <= arrayLen(arguments.issues); j++) {
				if (compareIssues(arguments.issues[i], arguments.issues[j]) > 0) {
					var tmp = arguments.issues[i];
					arguments.issues[i] = arguments.issues[j];
					arguments.issues[j] = tmp;
				}
			}
		}
	}

	private numeric function compareIssues(required struct leftIssue, required struct rightIssue) {
		var severityCompare = severityRank(arguments.leftIssue.severity) - severityRank(arguments.rightIssue.severity);
		if (severityCompare != 0) return severityCompare;

		var pathCompare = compareNoCase(arguments.leftIssue.path, arguments.rightIssue.path);
		if (pathCompare != 0) return pathCompare;

		return compareNoCase(arguments.leftIssue.code, arguments.rightIssue.code);
	}

	private numeric function severityRank(required string severity) {
		if (arguments.severity == "error") return 1;
		if (arguments.severity == "warning") return 2;
		return 3;
	}

}
