component output="false" {

	// bean cache
	this.beans = {};
	this.transients = {};

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

	public function getBean(beanName) {
		var b = 0;
		var meta = 0;
		if (beanExists(arguments.beanName, false, false)) {
			return this.beans[arguments.beanName];
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

	public function getBeanList() {
		var combined = structKeyList(this.beans);
		var trans = structKeyList(this.transients);
		if (len(combined) and len(trans)) {
			combined = combined & ",";
		}
		combined = combined & trans;
		return combined;
	}

	public function beanExists(required beanName, includeTransients=true, includeExternal=false) output="false" {
		return structKeyExists(this.beans, arguments.beanName) or (arguments.includeTransients and transientExists(arguments.beanName)) or
			(arguments.includeExternal and externalBeanExists(arguments.beanName));
	}

	private boolean function externalBeanExists(required beanName) output="false" {
		return structKeyExists(this, "externalBeanFactory") and this.externalBeanFactory.containsBean(arguments.beanName);
	}

	public void function loadBeansFromPath(
		required string beanPath hint="Absolute path to folder containing beans",
		string resourcesPath="resources",
		string resourcesBasePath="",
		boolean isFullReload=false,
		taffyRef={}
	) output="false" {
		var local = {};
		// cache all of the beans
		if (isFullReload) {
			this.beans = {};
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
			try {
				local.objBean = createObject("component", local.beanPath);
				if (isInstanceOf(local.objBean, "taffy.core.baseSerializer")) {
					this.transients[local.beanName] = local.beanPath;
				} else {
					this.beans[local.beanName] = local.objBean;
				}
			} catch (any e) {
				// skip cfc's with errors, but save info about them for display in the dashboard
				local.err = {};
				local.err.resource = local.beanName;
				local.err.exception = e;
				arrayAppend(arguments.taffyRef.status.skippedResources, local.err);
			}
		}
		// resolve dependencies
		for (local.b in this.beans) {
			local.bean = this.beans[local.b];
			local.beanMeta = getMetadata(local.bean);
			_recurse_ResolveDependencies(local.bean, local.beanMeta);
		}
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

	private function throwError() {
		cfthrow(attributecollection=arguments);
	}

}
