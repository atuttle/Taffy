component output="false" hint="Generates an OpenAPI 3.1 document from Taffy runtime metadata." {

	public struct function generate()
		hint="Returns an OpenAPI 3.1 struct describing all registered resources." {
		return generateWithSourceMap().spec;
	}

	public struct function generateWithSourceMap()
		hint="Returns the generated OpenAPI 3.1 struct with an internal Taffy source map." {

		var settings = application._taffy.settings;
		var endpoints = application._taffy.endpoints;
		var matchOrder = application._taffy.uriMatchOrder;
		var openapiCfg = structKeyExists(settings, "openapi") ? settings.openapi : {};
		var provider = getOpenApiProvider();
		var mediaTypes = collectResponseMediaTypes();
		var sourceMap = {};
		var globalTags = [];
		var globalTagLookup = {};

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
			var pathTemplate = normalizePathTemplate(endpoint.srcUri, endpoint.tokens);

			for (var verb in endpoint.methods) {
				if (!listFindNoCase(validVerbs, verb)) continue;
				var funcName = endpoint.methods[verb];
				if (!structKeyExists(funcs, funcName)) continue;
				var func = funcs[funcName];
				if (hasAnyKey(func, "taffy_docs_hide,taffy:docs:hide,taffy_dashboard_hide,taffy:dashboard:hide")) continue;
				var verbName = lcase(verb);
				pathItem[verbName] = buildOperation(verb, func, endpoint, beanMeta, mediaTypes, provider, bean, funcs);
				collectOperationTags(pathItem[verbName], globalTags, globalTagLookup);
				sourceMap["/paths/" & pointerSegment(pathTemplate) & "/" & pointerSegment(verbName)] = buildSourceMapEntry(endpoint, func, verb, pathTemplate);
			}

			if (!structIsEmpty(pathItem)) {
				doc.paths[pathTemplate] = pathItem;
			}
		}

		if (arrayLen(globalTags)) {
			doc["tags"] = globalTags;
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

		return {
			spec = finalDoc,
			sourceMap = sourceMap
		};
	}

	private struct function buildInfo(required struct settings, required struct openapiCfg) {
		var info = {
			"title": arguments.settings.docs.APIName,
			"version": arguments.settings.docs.APIVersion,
			"description": arguments.settings.docs.APIName & " OpenAPI specification.",
			"contact": {
				"name": arguments.settings.docs.APIName
			}
		};
		if (structKeyExists(arguments.openapiCfg, "description") && len(trim(arguments.openapiCfg.description))) info["description"] = arguments.openapiCfg.description;
		if (structKeyExists(arguments.openapiCfg, "contact") && isStruct(arguments.openapiCfg.contact)) info["contact"] = arguments.openapiCfg.contact;
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
		if (
			!structKeyExists(op, "description")
			|| !isSimpleValue(op.description)
			|| !len(trim(op.description))
		) {
			op["description"] = structKeyExists(op, "summary") ? op.summary : op.operationId;
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
			schema["default"] = coerceSchemaDefault(arguments.param.default, schema);
		}
		return schema;
	}

	private any function coerceSchemaDefault(required any defaultValue, required struct schema) {
		if (!isSimpleValue(arguments.defaultValue) || !structKeyExists(arguments.schema, "type")) {
			return arguments.defaultValue;
		}

		var schemaType = lcase(arguments.schema.type);
		var value = arguments.defaultValue;
		if (schemaType == "boolean") {
			return listFindNoCase("true,yes,1", trim(value)) > 0;
		}
		if (schemaType == "integer" && isNumeric(value)) {
			return int(value);
		}
		if (schemaType == "number" && isNumeric(value)) {
			return val(value);
		}
		return value;
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

	private void function collectOperationTags(required struct operation, required array globalTags, required struct globalTagLookup) {
		if (!structKeyExists(arguments.operation, "tags") || !isArray(arguments.operation.tags)) {
			return;
		}

		for (var i = 1; i <= arrayLen(arguments.operation.tags); i++) {
			var tagName = arguments.operation.tags[i];
			if (isSimpleValue(tagName) && len(tagName) && !structKeyExists(arguments.globalTagLookup, tagName)) {
				arguments.globalTagLookup[tagName] = true;
				arrayAppend(arguments.globalTags, {
					"name": tagName
				});
			}
		}
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

		return normalizeOpenApiDocKeys(docs);
	}

	private any function normalizeOpenApiDocKeys(required any value, string context = "") {
		if (isArray(arguments.value)) {
			var normalizedArray = [];
			for (var i = 1; i <= arrayLen(arguments.value); i++) {
				arrayAppend(normalizedArray, normalizeOpenApiDocKeys(arguments.value[i], getOpenApiArrayItemContext(arguments.context)));
			}
			return normalizedArray;
		}

		if (!isStruct(arguments.value)) {
			return arguments.value;
		}

		var normalizedStruct = {};
		var preserveMapKeys = shouldPreserveOpenApiMapKeys(arguments.context);
		for (var key in arguments.value) {
			var normalizedKey = preserveMapKeys ? normalizeOpenApiMapKey(key, arguments.context) : normalizeOpenApiKeywordKey(key);
			normalizedStruct[normalizedKey] = normalizeOpenApiDocKeys(
				arguments.value[key],
				getOpenApiChildContext(arguments.context, normalizedKey)
			);
		}

		return normalizedStruct;
	}

	private string function getOpenApiArrayItemContext(required string context) {
		var contextName = lcase(arguments.context);
		if (listFindNoCase("allOf,anyOf,oneOf,prefixItems", contextName)) {
			return "schema";
		}
		if (contextName == "parameters") {
			return "parameter";
		}
		if (contextName == "servers") {
			return "server";
		}
		if (contextName == "tags") {
			return "tag";
		}
		return arguments.context;
	}

	private boolean function shouldPreserveOpenApiMapKeys(required string context) {
		return listFindNoCase(
			"responses,content,properties,patternProperties,headers,examples,links,callbacks,schemas,parameters,requestBodies,securitySchemes",
			arguments.context
		) > 0;
	}

	private string function normalizeOpenApiMapKey(required string key, required string context) {
		if (lcase(arguments.context) == "responses" && lcase(arguments.key) == "default") {
			return "default";
		}
		return arguments.key;
	}

	private string function getOpenApiChildContext(required string context, required string key) {
		var contextName = lcase(arguments.context);
		var keyName = lcase(arguments.key);
		if (listFindNoCase("responses,content,properties,patternProperties,schemas,headers,examples,links,callbacks,securitySchemes,parameters,requestBodies", keyName)) {
			return keyName;
		}
		if (listFindNoCase("properties,patternProperties,schemas", contextName)) {
			return "schema";
		}
		if (contextName == "responses") {
			return "response";
		}
		if (contextName == "content") {
			return "mediaType";
		}
		if (contextName == "parameters") {
			return "parameter";
		}
		if (contextName == "headers") {
			return "header";
		}
		if (contextName == "examples") {
			return "example";
		}
		if (contextName == "links") {
			return "link";
		}
		if (contextName == "requestbodies") {
			return "requestBody";
		}
		if (contextName == "securityschemes") {
			return "securityScheme";
		}
		if (listFindNoCase("schema,items,additionalProperties,contains,unevaluatedProperties,not,if,then,else,propertyNames", keyName)) {
			return "schema";
		}
		if (listFindNoCase("allOf,anyOf,oneOf,prefixItems", keyName)) {
			return keyName;
		}
		return keyName;
	}

	private string function normalizeOpenApiKeywordKey(required string key) {
		switch (lcase(arguments.key)) {
			case "$ref": return "$ref";
			case "additionalproperties": return "additionalProperties";
			case "allowemptyvalue": return "allowEmptyValue";
			case "allowreserved": return "allowReserved";
			case "allof": return "allOf";
			case "anyof": return "anyOf";
			case "callbacks": return "callbacks";
			case "components": return "components";
			case "contact": return "contact";
			case "contains": return "contains";
			case "content": return "content";
			case "default": return "default";
			case "deprecated": return "deprecated";
			case "description": return "description";
			case "discriminator": return "discriminator";
			case "else": return "else";
			case "encoding": return "encoding";
			case "enum": return "enum";
			case "example": return "example";
			case "examples": return "examples";
			case "exclusivemaximum": return "exclusiveMaximum";
			case "exclusiveminimum": return "exclusiveMinimum";
			case "explode": return "explode";
			case "externaldocs": return "externalDocs";
			case "format": return "format";
			case "headers": return "headers";
			case "if": return "if";
			case "in": return "in";
			case "info": return "info";
			case "items": return "items";
			case "license": return "license";
			case "links": return "links";
			case "maxitems": return "maxItems";
			case "maxlength": return "maxLength";
			case "maximum": return "maximum";
			case "mediatype": return "mediaType";
			case "minitems": return "minItems";
			case "minlength": return "minLength";
			case "minimum": return "minimum";
			case "multipleof": return "multipleOf";
			case "name": return "name";
			case "not": return "not";
			case "nullable": return "nullable";
			case "oneof": return "oneOf";
			case "openapi": return "openapi";
			case "operationid": return "operationId";
			case "parameters": return "parameters";
			case "paths": return "paths";
			case "pattern": return "pattern";
			case "patternproperties": return "patternProperties";
			case "prefixitems": return "prefixItems";
			case "properties": return "properties";
			case "propertynames": return "propertyNames";
			case "readonly": return "readOnly";
			case "requestbodies": return "requestBodies";
			case "requestbody": return "requestBody";
			case "required": return "required";
			case "responses": return "responses";
			case "schema": return "schema";
			case "schemas": return "schemas";
			case "security": return "security";
			case "securityschemes": return "securitySchemes";
			case "servers": return "servers";
			case "style": return "style";
			case "summary": return "summary";
			case "tags": return "tags";
			case "then": return "then";
			case "title": return "title";
			case "type": return "type";
			case "unevaluatedproperties": return "unevaluatedProperties";
			case "uniqueitems": return "uniqueItems";
			case "url": return "url";
			case "version": return "version";
			case "writeonly": return "writeOnly";
			case "xml": return "xml";
		}
		return arguments.key;
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

	private struct function buildSourceMapEntry(required struct endpoint, required struct func, required string verb, required string pathTemplate) {
		var entry = {
			resource = arguments.endpoint.beanName,
			method = arguments.func.name,
			docsMethod = arguments.func.name & "OpenAPIDocs",
			operation = ucase(arguments.verb) & " " & arguments.pathTemplate
		};
		var undeclaredPathTokens = getUndeclaredPathTokens(arguments.endpoint, arguments.func);
		if (arrayLen(undeclaredPathTokens)) {
			entry.undeclaredPathTokens = undeclaredPathTokens;
		}

		return entry;
	}

	private array function getUndeclaredPathTokens(required struct endpoint, required struct func) {
		var declared = {};
		var params = structKeyExists(arguments.func, "parameters") ? arguments.func.parameters : [];
		for (var p = 1; p <= arrayLen(params); p++) {
			if (structKeyExists(params[p], "name") && isSimpleValue(params[p].name)) {
				declared[lcase(params[p].name)] = true;
			}
		}

		var undeclared = [];
		for (var t = 1; t <= arrayLen(arguments.endpoint.tokens); t++) {
			var token = arguments.endpoint.tokens[t];
			if (!structKeyExists(declared, lcase(token))) {
				arrayAppend(undeclared, token);
			}
		}

		return undeclared;
	}

	private string function pointerSegment(required string value) {
		var out = replace(arguments.value, "~", "~0", "all");
		out = replace(out, "/", "~1", "all");
		return out;
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
