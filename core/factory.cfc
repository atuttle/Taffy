component output="false" {

	// bean cache
	this.beans = {};
	// bean paths (createObject on first getBean)
	this.paths = {};
	this.transients = {};
	// parsed cfc metadata cache (no createObject at load)
	this.metaCache = {};
	// absolute paths to cfc files (for re-parse)
	this.filePaths = {};
	// beans that declare taffy:uri
	this.resourceNames = {};

	public function init(externalBeanFactory) {
		if (structKeyExists(arguments, "externalBeanFactory")) {
			this.externalBeanFactory = arguments.externalBeanFactory;
		}
		return this;
	}

	// Proxy to beanExists to provide similar interface to ColdSpring
	public function containsBean(beanName) {
		return beanExists(arguments.beanName);
	}

	public function transientExists(beanName) {
		return structKeyExists(this.transients, arguments.beanName);
	}

	public function pathExists(beanName) {
		return structKeyExists(this.paths, arguments.beanName);
	}

	public function getBean(beanName) {
		var b = 0;
		var meta = 0;
		if (structKeyExists(this.beans, arguments.beanName)) {
			return this.beans[arguments.beanName];
		} else if (pathExists(arguments.beanName)) {
			return loadBeanFromPath(arguments.beanName);
		} else if (transientExists(arguments.beanName)) {
			b = createObject('component', this.transients[arguments.beanName]);
			meta = getMetadata(b);
			_recurse_ResolveDependencies(b, meta);
			return b;
		} else if (externalBeanExists(arguments.beanName)) {
			return this.externalBeanFactory.getBean(arguments.beanName);
		} else {
			throwError(message="Bean name '#arguments.beanName#' not found.", type="Taffy.Factory.BeanNotFound");
		}
	}

	// metadata without createObject when possible (Lucee getComponentMetadata runs CFC bodies)
	public function getBeanMetaData(beanName) {
		if (structKeyExists(this.metaCache, arguments.beanName)) {
			return this.metaCache[arguments.beanName];
		}
		if (structKeyExists(this.beans, arguments.beanName)) {
			return getMetadata(this.beans[arguments.beanName]);
		}
		if (structKeyExists(this.filePaths, arguments.beanName)) {
			return parseCfcMetaData(this.filePaths[arguments.beanName]);
		}
		if (pathExists(arguments.beanName)) {
			return parseCfcMetaData(expandPath("/" & replace(this.paths[arguments.beanName], ".", "/", "all") & ".cfc"));
		}
		if (transientExists(arguments.beanName)) {
			return getComponentMetadata(this.transients[arguments.beanName]);
		}
		if (externalBeanExists(arguments.beanName)) {
			return getMetadata(this.externalBeanFactory.getBean(arguments.beanName));
		}
		throwError(message="Bean name '#arguments.beanName#' not found.", type="Taffy.Factory.BeanNotFound");
	}

	public function getBeanList() {
		var combined = structKeyList(this.beans);
		var pathKeys = structKeyList(this.paths);
		var trans = structKeyList(this.transients);
		if (len(combined) and len(pathKeys)) {
			combined = combined & ",";
		}
		combined = combined & pathKeys;
		if (len(combined) and len(trans)) {
			combined = combined & ",";
		}
		combined = combined & trans;
		return combined;
	}

	public function getResourceBeanList() {
		return structKeyList(this.resourceNames);
	}

	public function beanExists(required beanName, includeTransients=true, includeExternal=false) output="false" {
		return structKeyExists(this.beans, arguments.beanName) or pathExists(arguments.beanName) or
			(arguments.includeTransients and transientExists(arguments.beanName)) or
			(arguments.includeExternal and externalBeanExists(arguments.beanName));
	}

	private boolean function externalBeanExists(required beanName) output="false" {
		return structKeyExists(this, "externalBeanFactory") and this.externalBeanFactory.containsBean(arguments.beanName);
	}

	private function loadBeanFromPath(required string beanName) {
		var beanPath = this.paths[arguments.beanName];
		var objBean = createObject("component", beanPath);
		structDelete(this.paths, arguments.beanName);
		this.beans[arguments.beanName] = objBean;
		_recurse_ResolveDependencies(objBean, getMetadata(objBean));
		return objBean;
	}

	public void function loadBeansFromPath(
		required string beanPath hint="Absolute path to folder containing beans",
		string resourcesPath="resources",
		string resourcesBasePath="",
		boolean isFullReload=false,
		taffyRef={}
	) output="false" {
		var local = {};
		// cache bean paths (createObject on first getBean)
		if (isFullReload) {
			this.beans = {};
			this.paths = {};
			this.transients = {};
			this.metaCache = {};
			this.filePaths = {};
			this.resourceNames = {};
			arguments.taffyRef.status.skippedResources = []; // empty out the array on factory reloads
			arguments.taffyRef.beanList = "";
		}
		// if the folder doesn't exist, do nothing
		if (!directoryExists(arguments.beanPath)) {
			return;
		}
		// get list of beans to load
		local.beanQuery = directoryList(arguments.beanPath, true, "query", "*.cfc");
		for (var row in local.beanQuery) {
			local.beanName = filePathToBeanName(row.directory, row.name, arguments.resourcesBasePath);
			local.beanPath = filePathToBeanPath(row.directory, row.name, arguments.resourcesPath, arguments.resourcesBasePath);
			local.absFile = row.directory & "/" & row.name;
			try {
				local.meta = parseCfcMetaData(local.absFile);
				this.metaCache[local.beanName] = local.meta;
				this.filePaths[local.beanName] = local.absFile;
				if (isSerializerMetadata(local.meta)) {
					this.transients[local.beanName] = local.beanPath;
				} else {
					this.paths[local.beanName] = local.beanPath;
					if (metadataHasTaffyUri(local.meta)) {
						this.resourceNames[local.beanName] = true;
					}
				}
			} catch (any e) {
				// skip cfc's with errors, but save info about them for display in the dashboard
				local.err = {};
				local.err.resource = local.beanName;
				local.err.exception = e;
				arrayAppend(arguments.taffyRef.status.skippedResources, local.err);
			}
		}
	}

	// parse CFC source for uri/verb/serializer hints without running the component
	// (Lucee getComponentMetadata executes the CFC body). Supports script and tag syntax.
	private struct function parseCfcMetaData(required string absPath) {
		var src = fileRead(arguments.absPath);
		var meta = {
			name: listLast(replace(arguments.absPath, "\", "/", "all"), "/"),
			functions: []
		};
		var seen = {};
		// chr(60) avoids the CFML parser treating a literal tag opener as a real tag
		var cffn = chr(60) & "cffunction";
		meta.name = replaceNoCase(meta.name, ".cfc", "");

		var uriFind = reFindNoCase('taffy[_:]uri\s*=\s*["'']([^"'']+)["'']', src, 1, true);
		if (isStruct(uriFind) && structKeyExists(uriFind, "pos") && arrayLen(uriFind.pos) >= 2 && uriFind.pos[2] > 0) {
			meta["taffy:uri"] = mid(src, uriFind.pos[2], uriFind.len[2]);
		}

		var aopFind = reFindNoCase('taffy[_:]aopbean\s*=\s*["'']([^"'']+)["'']', src, 1, true);
		if (isStruct(aopFind) && structKeyExists(aopFind, "pos") && arrayLen(aopFind.pos) >= 2 && aopFind.pos[2] > 0) {
			meta["taffy:aopbean"] = mid(src, aopFind.pos[2], aopFind.len[2]);
		}

		if (reFindNoCase('extends\s*=\s*["''][^"'']*baseSerializer', src)
			or reFindNoCase('extends\s*=\s*["'']taffy\.core\.baseSerializer["'']', src)
			or reFindNoCase('function\s+getAs\w+\s*\([^\)]*\)[^{\n]*taffy[_:]mime\s*=', src)
			or reFindNoCase(cffn & '\b[^>]*\bname\s*=\s*["'']getAs[^"'']*["''][^>]*taffy[_:]mime\s*=', src)
			or reFindNoCase(cffn & '\b[^>]*taffy[_:]mime\s*=[^>]*\bname\s*=\s*["'']getAs', src)) {
			meta.extends = { name: "taffy.core.baseSerializer" };
		}

		var verbNames = ["get", "post", "put", "patch", "delete", "head", "options"];
		for (var verb in verbNames) {
			if (
				reFindNoCase("function\s+#verb#\s*\(", src)
				or reFindNoCase(cffn & '\b[^>]*\bname\s*=\s*["'']#verb#["'']', src)
			) {
				arrayAppend(meta.functions, { name: verb });
				seen[lcase(verb)] = true;
			}
		}

		// function foo taffy:verb="bar"
		var attrFind = reFindNoCase('function\s+(\w+)[^{\n]*taffy[_:]verb\s*=\s*["'']([^"'']+)["'']', src, 1, true);
		while (isStruct(attrFind) && structKeyExists(attrFind, "pos") && arrayLen(attrFind.pos) >= 3 && attrFind.pos[1] > 0) {
			var scriptName = mid(src, attrFind.pos[2], attrFind.len[2]);
			if (!structKeyExists(seen, lcase(scriptName) & ":" & lcase(mid(src, attrFind.pos[3], attrFind.len[3])))) {
				arrayAppend(meta.functions, {
					name: scriptName,
					"taffy:verb": mid(src, attrFind.pos[3], attrFind.len[3])
				});
				seen[lcase(scriptName) & ":" & lcase(mid(src, attrFind.pos[3], attrFind.len[3]))] = true;
			}
			var nextPos = attrFind.pos[1] + attrFind.len[1];
			if (nextPos >= len(src)) break;
			attrFind = reFindNoCase('function\s+(\w+)[^{\n]*taffy[_:]verb\s*=\s*["'']([^"'']+)["'']', src, nextPos, true);
		}

		// tag syntax: name/taffy:verb attrs in any order
		var tagFind = reFindNoCase(cffn & '\b([^>]*)>', src, 1, true);
		while (isStruct(tagFind) && structKeyExists(tagFind, "pos") && arrayLen(tagFind.pos) >= 2 && tagFind.pos[1] > 0) {
			var attrs = mid(src, tagFind.pos[2], tagFind.len[2]);
			var nameFind = reFindNoCase('\bname\s*=\s*["'']([^"'']+)["'']', attrs, 1, true);
			var verbFind = reFindNoCase('taffy[_:]verb\s*=\s*["'']([^"'']+)["'']', attrs, 1, true);
			if (
				isStruct(nameFind) && structKeyExists(nameFind, "pos") && arrayLen(nameFind.pos) >= 2 && nameFind.pos[2] > 0
				&& isStruct(verbFind) && structKeyExists(verbFind, "pos") && arrayLen(verbFind.pos) >= 2 && verbFind.pos[2] > 0
			) {
				var tagName = mid(attrs, nameFind.pos[2], nameFind.len[2]);
				var tagVerb = mid(attrs, verbFind.pos[2], verbFind.len[2]);
				var tagKey = lcase(tagName) & ":" & lcase(tagVerb);
				if (!structKeyExists(seen, tagKey)) {
					arrayAppend(meta.functions, {
						name: tagName,
						"taffy:verb": tagVerb
					});
					seen[tagKey] = true;
				}
			}
			var tagNext = tagFind.pos[1] + tagFind.len[1];
			if (tagNext >= len(src)) break;
			tagFind = reFindNoCase(cffn & '\b([^>]*)>', src, tagNext, true);
		}

		return meta;
	}

	private boolean function metadataHasTaffyUri(required struct meta) {
		return (structKeyExists(arguments.meta, "taffy_uri") && len(arguments.meta.taffy_uri))
			or (structKeyExists(arguments.meta, "taffy:uri") && len(arguments.meta["taffy:uri"]));
	}

	private function filePathToBeanPath(path, filename, resourcesPath, resourcesBasePath) {
		var beanPath = "";
		if (len(resourcesBasePath) eq 0) {
			arguments.resourcesBasePath = "!@$%^&*()";
		}
		beanPath =
			resourcesPath
			& "."
			& replaceList(
				replace(path, resourcesBasePath, ""),
				"/,\",
				".,."
			)
			& "."
			& replace(
				filename,
				".cfc",
				""
			);
		beanPath = replace(beanPath, "..", ".", "ALL");
		if (left(beanPath, 1) eq ".") {
			beanPath = right(beanPath, len(beanPath)-1);
		}
		return beanPath;
	}

	private function filePathToBeanName(path, filename, basepath) {
		if (len(basepath) eq 0) {
			arguments.basePath = "!@$%^&*()";
		}
		return
			replaceList(
				replace(path, basepath, ""),
				"/,\",
				","
			)
			& replace(
				filename,
				".cfc",
				""
			);
	}

	private function _recurse_ResolveDependencies(required bean, required struct metaData) {
		var local = {};
		if (structKeyExists(arguments.metaData, "functions") and isArray(arguments.metaData.functions)) {
			for (local.f = 1; local.f <= arrayLen(arguments.metaData.functions); local.f++) {
				local.fname = arguments.metaData.functions[local.f].name;
				if (len(local.fname) gt 3) {
					local.propName = right(local.fname, len(local.fname)-3);
					if (left(local.fname, 3) eq "set" and beanExists(local.propName, true, true)) {
						invoke(arguments.bean, local.fname, [getBean(local.propName)]);
					}
				}
			}
		}
		if (structKeyExists(arguments.metaData, "properties") and isArray(arguments.metaData.properties)) {
			for (local.p = 1; local.p <= arrayLen(arguments.metaData.properties); local.p++) {
				local.propName = arguments.metaData.properties[local.p].name;
				if (beanExists(local.propName, true, true)) {
					arguments.bean[local.propName] = getBean(local.propName);
				}
			}
		}
		if (structKeyExists(arguments.metaData, "extends") and isStruct(arguments.metaData.extends)) {
			_recurse_ResolveDependencies(arguments.bean, arguments.metaData.extends);
		}
	}

	/**
	 * Walks the inheritance chain to check if metadata extends baseSerializer.
	 * Replaces isInstanceOf() which fails on Lucee when extends resolves
	 * to a relative path instead of a mapping-prefixed path.
	 */
	private boolean function isSerializerMetadata(required struct meta) output="false" {
		var walk = arguments.meta;
		while (structKeyExists(walk, "name")) {
			if (listLast(walk.name, ".") == "baseSerializer") return true;
			if (!structKeyExists(walk, "extends")) break;
			walk = walk.extends;
		}
		return false;
	}

	private function throwError() {
		cfthrow(attributecollection=arguments);
	}

}
