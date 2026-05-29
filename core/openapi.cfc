component output="false" hint="Generates an OpenAPI 3.1 document from Taffy runtime metadata." {

	public struct function generate()
		hint="Returns an OpenAPI 3.1 struct describing all registered resources." {

		var settings = application._taffy.settings;
		var endpoints = application._taffy.endpoints;
		var matchOrder = application._taffy.uriMatchOrder;
		var openapiCfg = structKeyExists(settings, "openapi") ? settings.openapi : {};
		var provider = getOpenApiProvider();
		var mediaTypes = collectResponseMediaTypes();

		var doc = {
			"openapi": "3.1.0",
			"info": buildInfo(settings, openapiCfg),
			"paths": {}
		};

		var servers = buildServers(openapiCfg);
		if (arrayLen(servers)) {
			doc["servers"] = servers;
		}

		for (var i = 1; i <= arrayLen(matchOrder); i++) {
			var endpoint = endpoints[matchOrder[i]];
			var bean = application._taffy.factory.getBean(endpoint.beanName);
			var beanMeta = getMetaData(bean);

			if (hasAnyKey(beanMeta, "taffy_docs_hide,taffy:docs:hide,taffy_dashboard_hide,taffy:dashboard:hide")) {
				continue;
			}

			var funcs = collectFunctions(beanMeta);
			var pathItem = {};
			var validVerbs = "get,put,post,delete,options,head,patch,trace";

			for (var verb in endpoint.methods) {
				if (!listFindNoCase(validVerbs, verb)) continue;
				var funcName = endpoint.methods[verb];
				if (!structKeyExists(funcs, funcName)) continue;
				var func = funcs[funcName];
				if (hasAnyKey(func, "taffy_docs_hide,taffy:docs:hide,taffy_dashboard_hide,taffy:dashboard:hide")) continue;
				pathItem[lcase(verb)] = buildOperation(verb, func, endpoint, beanMeta, mediaTypes, provider, bean, funcs);
			}

			if (!structIsEmpty(pathItem)) {
				doc.paths[normalizePathTemplate(endpoint.srcUri, endpoint.tokens)] = pathItem;
			}
		}

		var components = provider.getComponents();
		if (isStruct(components) && !structIsEmpty(components)) {
			doc["components"] = components;
		}

		var finalDoc = provider.afterGenerate(doc);
		if (!isStruct(finalDoc)) {
			throw(
				message="Invalid OpenAPI provider",
				detail="The provider afterGenerate() method must return a struct."
			);
		}

		return finalDoc;
	}

	private struct function buildInfo(required struct settings, required struct openapiCfg) {
		var info = {
			"title": arguments.settings.docs.APIName,
			"version": arguments.settings.docs.APIVersion
		};
		if (structKeyExists(arguments.openapiCfg, "description")) info["description"] = arguments.openapiCfg.description;
		if (structKeyExists(arguments.openapiCfg, "contact")) info["contact"] = arguments.openapiCfg.contact;
		if (structKeyExists(arguments.openapiCfg, "license")) info["license"] = arguments.openapiCfg.license;
		return info;
	}

	private array function buildServers(required struct openapiCfg) {
		if (structKeyExists(arguments.openapiCfg, "servers") && isArray(arguments.openapiCfg.servers)) {
			return arguments.openapiCfg.servers;
		}
		var host = cgi.http_host;
		if (!len(host)) return [];
		var isHttps = cgi.server_port == 443 || (structKeyExists(cgi, "https") && cgi.https == "on");
		var scheme = isHttps ? "https" : "http";
		var scriptDir = getDirectoryFromPath(cgi.script_name);
		if (right(scriptDir, 1) == "/" && len(scriptDir) > 1) {
			scriptDir = left(scriptDir, len(scriptDir) - 1);
		}
		return [ { "url": scheme & "://" & host & scriptDir } ];
	}

	private array function collectResponseMediaTypes()
		hint="Unique MIME type strings Taffy can return, derived from registered serializers." {
		var mimes = {};
		for (var ext in application._taffy.settings.mimeExtensions) {
			for (var part in listToArray(application._taffy.settings.mimeExtensions[ext], ";")) {
				mimes[trim(part)] = true;
			}
		}
		var out = [];
		for (var m in mimes) arrayAppend(out, m);
		arraySort(out, "text");
		return out;
	}

	private struct function collectFunctions(required struct metadata)
		hint="Flatten the cfc's function metadata (including inherited) keyed by name. Child overrides parent." {
		var result = {};
		if (structKeyExists(arguments.metadata, "extends") && arguments.metadata.extends.fullname != "taffy.core.resource") {
			result = collectFunctions(arguments.metadata.extends);
		}
		if (!structKeyExists(arguments.metadata, "functions") || !isArray(arguments.metadata.functions)) {
			return result;
		}
		for (var f = 1; f <= arrayLen(arguments.metadata.functions); f++) {
			var func = arguments.metadata.functions[f];
			if (structKeyExists(func, "access") && (func.access == "private" || func.access == "package")) continue;
			result[func.name] = func;
		}
		return result;
	}

	private struct function buildOperation(
		required string verb,
		required struct func,
		required struct endpoint,
		required struct beanMeta,
		required array mediaTypes,
		any provider,
		any bean,
		struct funcs
	) {
		var openapiProvider = structKeyExists(arguments, "provider") ? arguments.provider : getOpenApiProvider();
		var excludedParameters = buildNameLookup(openapiProvider.getExcludeParameters());
		var op = {
			"tags": [ getResourceTag(arguments.beanMeta, arguments.endpoint.beanName) ],
			"operationId": arguments.endpoint.beanName & "_" & lcase(arguments.verb)
		};

		if (structKeyExists(arguments.beanMeta, "taffy:docs:name")) {
			op["summary"] = arguments.beanMeta["taffy:docs:name"];
		} else if (structKeyExists(arguments.beanMeta, "taffy_docs_name")) {
			op["summary"] = arguments.beanMeta["taffy_docs_name"];
		}
		if (structKeyExists(arguments.func, "hint")) op["description"] = arguments.func.hint;

		var tokenLookup = {};
		for (var t = 1; t <= arrayLen(arguments.endpoint.tokens); t++) {
			tokenLookup[lcase(arguments.endpoint.tokens[t])] = arguments.endpoint.tokens[t];
		}

		var parameters = [];
		var bodyParams = [];
		var declaredPathTokens = {};
		var params = structKeyExists(arguments.func, "parameters") ? arguments.func.parameters : [];
		var isBodyVerb = listFindNoCase("post,put,patch", arguments.verb) > 0;

		for (var p = 1; p <= arrayLen(params); p++) {
			var param = params[p];
			if (hasAnyKey(param, "taffy_docs_hide,taffy:docs:hide,taffy_dashboard_hide,taffy:dashboard:hide")) continue;
			if (structKeyExists(tokenLookup, lcase(param.name))) {
				// use the token's original casing so the parameter name matches the path template exactly
				arrayAppend(parameters, buildParameter(param, "path", true, tokenLookup[lcase(param.name)]));
				declaredPathTokens[lcase(param.name)] = true;
			} else if (isBodyVerb) {
				arrayAppend(bodyParams, param);
			} else {
				var required = structKeyExists(param, "required") && param.required;
				arrayAppend(parameters, buildParameter(param, "query", required));
			}
		}

		// backfill any path tokens the resource didn't declare as args — OpenAPI requires a parameter for every {token}
		for (var t2 = 1; t2 <= arrayLen(arguments.endpoint.tokens); t2++) {
			var tok = arguments.endpoint.tokens[t2];
			if (!structKeyExists(declaredPathTokens, lcase(tok))) {
				arrayAppend(parameters, {
					"name": tok,
					"in": "path",
					"required": true,
					"schema": { "type": "string" }
				});
			}
		}

		if (arrayLen(parameters)) op["parameters"] = parameters;
		if (isBodyVerb && arrayLen(bodyParams)) op["requestBody"] = buildRequestBody(bodyParams);
		op = applyExcludedParameters(op, excludedParameters);
		op["responses"] = openapiProvider.getResponseDefaults(arguments.mediaTypes);
		op = addGlobalParameters(op, openapiProvider.getGlobalParameters());

		if (structKeyExists(arguments, "bean") && structKeyExists(arguments, "funcs")) {
			op = deepMergeStructs(op, getOperationDocs(arguments.bean, arguments.funcs, arguments.func.name));
		}

		return op;
	}

	private struct function buildParameter(required struct param, required string location, required boolean required, string nameOverride = "") {
		var out = {
			"name": len(arguments.nameOverride) ? arguments.nameOverride : arguments.param.name,
			"in": arguments.location,
			"required": arguments.required,
			"schema": paramSchema(arguments.param)
		};
		if (structKeyExists(arguments.param, "hint")) out["description"] = arguments.param.hint;
		return out;
	}

	private struct function buildRequestBody(required array bodyParams) {
		var properties = {};
		var required = [];
		for (var p = 1; p <= arrayLen(arguments.bodyParams); p++) {
			var param = arguments.bodyParams[p];
			var schema = paramSchema(param);
			if (structKeyExists(param, "hint")) schema["description"] = param.hint;
			properties[param.name] = schema;
			if (structKeyExists(param, "required") && param.required) arrayAppend(required, param.name);
		}
		var bodySchema = { "type": "object", "properties": properties };
		if (arrayLen(required)) bodySchema["required"] = required;
		return {
			"content": {
				"application/json": { "schema": bodySchema },
				"application/x-www-form-urlencoded": { "schema": bodySchema }
			}
		};
	}

	private struct function paramSchema(required struct param) {
		var schema = cfmlTypeToSchema(structKeyExists(arguments.param, "type") ? arguments.param.type : "");
		if (structKeyExists(arguments.param, "default") && len(arguments.param.default)) {
			schema["default"] = arguments.param.default;
		}
		return schema;
	}

	private struct function cfmlTypeToSchema(required string type) {
		switch (lcase(trim(arguments.type))) {
			case "numeric": case "number": case "double": case "float":
				return { "type": "number" };
			case "integer":
				return { "type": "integer" };
			case "string":
				return { "type": "string" };
			case "boolean":
				return { "type": "boolean" };
			case "struct":
				return { "type": "object" };
			case "array":
				return { "type": "array" };
			case "date": case "datetime":
				return { "type": "string", "format": "date-time" };
			case "uuid": case "guid":
				return { "type": "string", "format": "uuid" };
			case "email":
				return { "type": "string", "format": "email" };
			case "url":
				return { "type": "string", "format": "uri" };
			case "": case "any": case "variablename":
				return {};
			default:
				return { "type": "string" };
		}
	}

	private string function getResourceTag(required struct beanMeta, required string beanName) {
		if (structKeyExists(arguments.beanMeta, "taffy:docs:name")) return arguments.beanMeta["taffy:docs:name"];
		if (structKeyExists(arguments.beanMeta, "taffy_docs_name")) return arguments.beanMeta["taffy_docs_name"];
		return arguments.beanName;
	}

	private any function getOpenApiProvider() {
		if (structKeyExists(application, "_taffy") && structKeyExists(application._taffy, "openapiProvider")) {
			return application._taffy.openapiProvider;
		}
		return createObject("component", "taffy.core.openapiProvider");
	}

	private struct function buildNameLookup(required array names) {
		var lookup = {};
		for (var i = 1; i <= arrayLen(arguments.names); i++) {
			if (isSimpleValue(arguments.names[i]) && len(arguments.names[i])) {
				lookup[lcase(arguments.names[i])] = true;
			}
		}
		return lookup;
	}

	private struct function applyExcludedParameters(required struct op, required struct excludedParameters) {
		if (structIsEmpty(arguments.excludedParameters)) {
			return arguments.op;
		}

		if (structKeyExists(arguments.op, "parameters") && isArray(arguments.op.parameters)) {
			for (var i = arrayLen(arguments.op.parameters); i >= 1; i--) {
				if (
					isStruct(arguments.op.parameters[i])
					&& structKeyExists(arguments.op.parameters[i], "name")
					&& structKeyExists(arguments.excludedParameters, lcase(arguments.op.parameters[i].name))
				) {
					arrayDeleteAt(arguments.op.parameters, i);
				}
			}
			if (!arrayLen(arguments.op.parameters)) {
				structDelete(arguments.op, "parameters");
			}
		}

		if (structKeyExists(arguments.op, "requestBody") && structKeyExists(arguments.op.requestBody, "content") && isStruct(arguments.op.requestBody.content)) {
			for (var mediaType in arguments.op.requestBody.content) {
				if (
					isStruct(arguments.op.requestBody.content[mediaType])
					&& structKeyExists(arguments.op.requestBody.content[mediaType], "schema")
					&& isStruct(arguments.op.requestBody.content[mediaType].schema)
				) {
					filterSchemaProperties(arguments.op.requestBody.content[mediaType].schema, arguments.excludedParameters);
				}
			}
			if (requestBodyHasNoProperties(arguments.op.requestBody)) {
				structDelete(arguments.op, "requestBody");
			}
		}

		return arguments.op;
	}

	private void function filterSchemaProperties(required struct schema, required struct excludedParameters) {
		if (structKeyExists(arguments.schema, "properties") && isStruct(arguments.schema.properties)) {
			var propertyNames = listToArray(structKeyList(arguments.schema.properties));
			for (var i = 1; i <= arrayLen(propertyNames); i++) {
				var propertyName = propertyNames[i];
				if (structKeyExists(arguments.excludedParameters, lcase(propertyName))) {
					structDelete(arguments.schema.properties, propertyName);
				}
			}
		}

		if (structKeyExists(arguments.schema, "required") && isArray(arguments.schema.required)) {
			for (var r = arrayLen(arguments.schema.required); r >= 1; r--) {
				if (structKeyExists(arguments.excludedParameters, lcase(arguments.schema.required[r]))) {
					arrayDeleteAt(arguments.schema.required, r);
				}
			}
			if (!arrayLen(arguments.schema.required)) {
				structDelete(arguments.schema, "required");
			}
		}
	}

	private boolean function requestBodyHasNoProperties(required struct requestBody) {
		if (!structKeyExists(arguments.requestBody, "content") || !isStruct(arguments.requestBody.content)) {
			return true;
		}

		for (var mediaType in arguments.requestBody.content) {
			if (
				isStruct(arguments.requestBody.content[mediaType])
				&& structKeyExists(arguments.requestBody.content[mediaType], "schema")
				&& isStruct(arguments.requestBody.content[mediaType].schema)
				&& structKeyExists(arguments.requestBody.content[mediaType].schema, "properties")
				&& isStruct(arguments.requestBody.content[mediaType].schema.properties)
				&& !structIsEmpty(arguments.requestBody.content[mediaType].schema.properties)
			) {
				return false;
			}
		}

		return true;
	}

	private struct function addGlobalParameters(required struct op, required array parameters) {
		if (!arrayLen(arguments.parameters)) {
			return arguments.op;
		}

		if (!structKeyExists(arguments.op, "parameters") || !isArray(arguments.op.parameters)) {
			arguments.op["parameters"] = [];
		}

		for (var i = 1; i <= arrayLen(arguments.parameters); i++) {
			if (isStruct(arguments.parameters[i]) && !hasParameter(arguments.op.parameters, arguments.parameters[i])) {
				arrayAppend(arguments.op.parameters, duplicate(arguments.parameters[i]));
			}
		}

		return arguments.op;
	}

	private boolean function hasParameter(required array parameters, required struct parameter) {
		var key = parameterKey(arguments.parameter);
		if (!len(key)) {
			return false;
		}

		for (var i = 1; i <= arrayLen(arguments.parameters); i++) {
			if (isStruct(arguments.parameters[i]) && parameterKey(arguments.parameters[i]) == key) {
				return true;
			}
		}

		return false;
	}

	private struct function getOperationDocs(required any bean, required struct funcs, required string funcName) {
		var docsMethodName = arguments.funcName & "OpenAPIDocs";
		if (!structKeyExists(arguments.funcs, docsMethodName)) {
			return {};
		}

		var docsMeta = arguments.funcs[docsMethodName];
		var params = structKeyExists(docsMeta, "parameters") ? docsMeta.parameters : [];
		for (var i = 1; i <= arrayLen(params); i++) {
			if (structKeyExists(params[i], "required") && params[i].required) {
				throw(
					message="Invalid OpenAPI docs method",
					detail="The #docsMethodName# method must not declare required arguments."
				);
			}
		}

		var docs = invoke(arguments.bean, docsMethodName);
		if (!isStruct(docs)) {
			throw(
				message="Invalid OpenAPI docs method",
				detail="The #docsMethodName# method must return a struct."
			);
		}

		return docs;
	}

	private struct function deepMergeStructs(required struct target, required struct source) {
		for (var key in arguments.source) {
			if (lcase(key) == "parameters" && isArray(arguments.source[key])) {
				if (!structKeyExists(arguments.target, key) || !isArray(arguments.target[key])) {
					arguments.target[key] = [];
				}
				arguments.target[key] = mergeParameters(arguments.target[key], arguments.source[key]);
			} else if (structKeyExists(arguments.target, key) && isStruct(arguments.target[key]) && isStruct(arguments.source[key])) {
				arguments.target[key] = deepMergeStructs(arguments.target[key], arguments.source[key]);
			} else {
				arguments.target[key] = duplicate(arguments.source[key]);
			}
		}

		return arguments.target;
	}

	private array function mergeParameters(required array baseParameters, required array incomingParameters) {
		var merged = [];
		var positions = {};

		for (var i = 1; i <= arrayLen(arguments.baseParameters); i++) {
			arrayAppend(merged, duplicate(arguments.baseParameters[i]));
			if (isStruct(arguments.baseParameters[i]) && len(parameterKey(arguments.baseParameters[i]))) {
				positions[parameterKey(arguments.baseParameters[i])] = arrayLen(merged);
			}
		}

		for (var p = 1; p <= arrayLen(arguments.incomingParameters); p++) {
			if (isStruct(arguments.incomingParameters[p]) && len(parameterKey(arguments.incomingParameters[p])) && structKeyExists(positions, parameterKey(arguments.incomingParameters[p]))) {
				merged[positions[parameterKey(arguments.incomingParameters[p])]] = duplicate(arguments.incomingParameters[p]);
			} else {
				arrayAppend(merged, duplicate(arguments.incomingParameters[p]));
				if (isStruct(arguments.incomingParameters[p]) && len(parameterKey(arguments.incomingParameters[p]))) {
					positions[parameterKey(arguments.incomingParameters[p])] = arrayLen(merged);
				}
			}
		}

		return merged;
	}

	private string function parameterKey(required struct parameter) {
		if (!structKeyExists(arguments.parameter, "in") || !structKeyExists(arguments.parameter, "name")) {
			return "";
		}
		return lcase(arguments.parameter["in"]) & "|" & lcase(arguments.parameter.name);
	}

	private string function normalizePathTemplate(required string uri, required array tokens)
		hint="Rebuild Taffy's URI as an OpenAPI path template: {name:regex} => {name}. Handles nested braces in token regexes." {
		var out = "";
		var i = 1;
		var tokenIdx = 1;
		var n = len(arguments.uri);
		while (i <= n) {
			var ch = mid(arguments.uri, i, 1);
			if (ch == "{") {
				// find the matching close brace, honoring nesting
				var depth = 1;
				var j = i + 1;
				while (j <= n && depth > 0) {
					var c2 = mid(arguments.uri, j, 1);
					if (c2 == "{") depth++;
					else if (c2 == "}") depth--;
					if (depth > 0) j++;
				}
				if (depth == 0 && tokenIdx <= arrayLen(arguments.tokens)) {
					out &= "{" & arguments.tokens[tokenIdx] & "}";
					tokenIdx++;
					i = j + 1;
					continue;
				}
			}
			out &= ch;
			i++;
		}
		return out;
	}

	private boolean function hasAnyKey(required struct target, required string keys) {
		for (var k in listToArray(arguments.keys)) {
			if (structKeyExists(arguments.target, k)) return true;
		}
		return false;
	}

}
