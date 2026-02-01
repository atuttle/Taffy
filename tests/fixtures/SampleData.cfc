component {

	/**
	 * Returns a sample query for testing queryToArray/queryToStruct
	 */
	function getSampleQuery() {
		return queryNew(
			"id,name,email,active",
			"integer,varchar,varchar,bit",
			[
				{ id: 1, name: "John Doe", email: "john@example.com", active: true },
				{ id: 2, name: "Jane Smith", email: "jane@example.com", active: true },
				{ id: 3, name: "Bob Wilson", email: "bob@example.com", active: false }
			]
		);
	}

	/**
	 * Returns a single-row query for testing queryToStruct
	 */
	function getSingleRowQuery() {
		return queryNew(
			"id,name,email",
			"integer,varchar,varchar",
			[{ id: 1, name: "Test User", email: "test@example.com" }]
		);
	}

	/**
	 * Returns sample struct data
	 */
	function getSampleStruct() {
		return {
			id: 123,
			name: "Test Item",
			tags: ["tag1", "tag2"],
			metadata: {
				created: now(),
				version: "1.0"
			}
		};
	}

	/**
	 * Returns sample array data
	 */
	function getSampleArray() {
		return [
			{ id: 1, value: "first" },
			{ id: 2, value: "second" },
			{ id: 3, value: "third" }
		];
	}

}
