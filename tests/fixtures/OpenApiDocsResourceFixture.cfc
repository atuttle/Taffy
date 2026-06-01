component output="false" {

	public struct function get() {
		return {};
	}

	public struct function getOpenAPIDocs() {
		return {
			"parameters": [
				{
					"name": "X-Trace-Id",
					"in": "header",
					"required": false,
					"schema": { "type": "string" },
					"description": "Endpoint trace header."
				}
			],
			"responses": {
				"404": { "description": "Not found." }
			}
		};
	}

	public struct function postOpenAPIDocs() {
		return {
			"requestBody": {
				"content": {
					"application/json": {
						"examples": {
							"sample": {
								"value": { "name": "Ada" }
							}
						}
					}
				}
			},
			"responses": {
				"201": { "description": "Created." }
			}
		};
	}

	public struct function updatePartialOpenAPIDocs() {
		return {
			"responses": {
				"202": { "description": "Accepted." }
			}
		};
	}

	public string function badOpenAPIDocs() {
		return "invalid";
	}

	public struct function requiredOpenAPIDocs(required string value) {
		return {};
	}

}
