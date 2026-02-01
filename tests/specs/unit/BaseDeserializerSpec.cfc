component extends="testbox.system.BaseSpec" {

	function run() {

		describe("BaseDeserializer", function() {

			beforeEach(function() {
				variables.deserializer = new taffy.core.baseDeserializer();
			});

			describe("getFromForm()", function() {

				it("should parse simple form data", function() {
					var body = "name=John&age=30";
					var result = deserializer.getFromForm(body);
					expect(result.name).toBe("John");
					expect(result.age).toBe("30");
				});

				it("should parse URL-encoded values", function() {
					var body = "name=John%20Doe&city=New%20York";
					var result = deserializer.getFromForm(body);
					expect(result.name).toBe("John Doe");
					expect(result.city).toBe("New York");
				});

				it("should handle empty values", function() {
					var body = "name=John&nickname=";
					var result = deserializer.getFromForm(body);
					expect(result.name).toBe("John");
					expect(result.nickname).toBe("");
				});

				it("should handle multiple values for same key as list", function() {
					var body = "color=red&color=blue&color=green";
					var result = deserializer.getFromForm(body);
					expect(result.color).toInclude("red");
					expect(result.color).toInclude("blue");
					expect(result.color).toInclude("green");
				});

				it("should handle special characters when URL encoded", function() {
					var body = "query=" & urlEncodedFormat("foo=bar&baz=qux");
					var result = deserializer.getFromForm(body);
					expect(result.query).toBe("foo=bar&baz=qux");
				});

				it("should handle plus signs as spaces", function() {
					// Note: urlDecode handles + as space
					var body = "name=John+Doe";
					var result = deserializer.getFromForm(body);
					expect(result.name).toBe("John Doe");
				});

			});

			describe("taffy:mime metadata", function() {

				it("should have taffy:mime for application/x-www-form-urlencoded", function() {
					var metadata = getMetadata(deserializer);
					var func = "";
					for (var f in metadata.functions) {
						if (f.name == "getFromForm") {
							func = f;
							break;
						}
					}
					expect(func).notToBeEmpty();
					var hasMime = structKeyExists(func, "taffy:mime")
						|| structKeyExists(func, "taffy_mime");
					expect(hasMime).toBeTrue();
				});

			});

		});

	}

}
