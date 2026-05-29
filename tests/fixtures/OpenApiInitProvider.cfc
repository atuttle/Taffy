component extends="taffy.core.openapiProvider" output="false" {

	variables.instanceId = createUUID();
	variables.initialized = false;

	public any function init() {
		variables.initialized = true;
		return this;
	}

	public string function getInstanceId() {
		return variables.instanceId;
	}

	public boolean function wasInitialized() {
		return variables.initialized;
	}

}
