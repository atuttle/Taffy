component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Save existing application context so we can restore it after
		if (structKeyExists(application, "_taffy")) {
			variables.savedTaffy = duplicate(application._taffy);
		}
		// Create a fresh API instance and bootstrap it to populate application._taffy with defaults
		variables.api = new core.api();
		variables.api.onApplicationStart();
		variables.settings = application._taffy.settings;
	}

	function afterAll() {
		// Restore original application context
		if (structKeyExists(variables, "savedTaffy")) {
			application._taffy = variables.savedTaffy;
		}
	}

	function run() {

		describe("Configuration", function() {

			describe("Default settings", function() {

				it("should have reloadKey default of 'reload'", function() {
					expect(settings.reloadKey).toBe("reload");
				});

				it("should have reloadPassword default of 'true'", function() {
					expect(settings.reloadPassword).toBe("true");
				});

				it("should have reloadOnEveryRequest default of false", function() {
					expect(settings.reloadOnEveryRequest).toBeFalse();
				});

				it("should have disableDashboard default of false", function() {
					expect(settings.disableDashboard).toBeFalse();
				});

				it("should have disabledDashboardRedirect default of empty string", function() {
					expect(settings.disabledDashboardRedirect).toBe("");
				});

				it("should have showDocsWhenDashboardDisabled default of false", function() {
					expect(settings.showDocsWhenDashboardDisabled).toBeFalse();
				});

				it("should have returnExceptionsAsJson default of true", function() {
					expect(settings.returnExceptionsAsJson).toBeTrue();
				});

				it("should have exposeTaffyHeaders default of true", function() {
					expect(settings.exposeTaffyHeaders).toBeTrue();
				});

				it("should have allowCrossDomain default of false", function() {
					expect(settings.allowCrossDomain).toBeFalse();
				});

				it("should have useEtags default of false", function() {
					expect(settings.useEtags).toBeFalse();
				});

				it("should have jsonp default of false", function() {
					expect(settings.jsonp).toBeFalse();
				});

				it("should have noDataSends204NoContent default of false", function() {
					expect(settings.noDataSends204NoContent).toBeFalse();
				});

				it("should have endpointURLParam default of 'endpoint'", function() {
					expect(settings.endpointURLParam).toBe("endpoint");
				});

				it("should have debugKey default of 'debug'", function() {
					expect(settings.debugKey).toBe("debug");
				});

				it("should have unhandledPaths default of '/flex2gateway'", function() {
					expect(settings.unhandledPaths).toBe("/flex2gateway");
				});

				it("should have globalHeaders default to empty struct", function() {
					expect(settings.globalHeaders).toBeStruct();
					expect(structIsEmpty(settings.globalHeaders)).toBeTrue();
				});

				it("should have exceptionLogAdapter default of LogToDevNull", function() {
					expect(settings.exceptionLogAdapter).toBe("taffy.bonus.LogToDevNull");
				});

				it("should have allowGoogleFonts default of true", function() {
					expect(settings.allowGoogleFonts).toBeTrue();
				});

			});

			describe("Serializer configuration", function() {

				it("should use nativeJsonSerializer by default", function() {
					expect(settings.serializer).toBe("taffy.core.nativeJsonSerializer");
				});

				it("should have nativeJsonSerializer extend baseSerializer", function() {
					var serializer = new core.nativeJsonSerializer();
					expect(serializer).toBeInstanceOf("core.baseSerializer");
				});

			});

			describe("Deserializer configuration", function() {

				it("should use nativeJsonDeserializer by default", function() {
					expect(settings.deserializer).toBe("taffy.core.nativeJsonDeserializer");
				});

				it("should have nativeJsonDeserializer extend baseDeserializer", function() {
					var deserializer = new core.nativeJsonDeserializer();
					expect(deserializer).toBeInstanceOf("core.baseDeserializer");
				});

				it("should support JSON content type via getFromJson", function() {
					var deserializer = new core.nativeJsonDeserializer();
					var meta = getMetadata(deserializer);
					var hasJsonSupport = false;
					for (var func in meta.functions) {
						if (func.name == "getFromJson") {
							hasJsonSupport = true;
							break;
						}
					}
					expect(hasJsonSupport).toBeTrue();
				});

				it("should support form-urlencoded content type via getFromForm", function() {
					var deserializer = new core.baseDeserializer();
					var meta = getMetadata(deserializer);
					var hasFormSupport = false;
					for (var func in meta.functions) {
						if (func.name == "getFromForm") {
							hasFormSupport = true;
							break;
						}
					}
					expect(hasFormSupport).toBeTrue();
				});

			});

			describe("MIME type configuration", function() {

				it("should detect mime types from serializer metadata", function() {
					var serializer = new core.nativeJsonSerializer();
					var meta = getMetadata(serializer);

					var jsonMime = "";
					for (var func in meta.functions) {
						if (func.name == "getAsJson") {
							if (structKeyExists(func, "taffy:mime")) {
								jsonMime = func["taffy:mime"];
							} else if (structKeyExists(func, "taffy_mime")) {
								jsonMime = func["taffy_mime"];
							}
							break;
						}
					}
					expect(jsonMime).toInclude("application/json");
				});

				it("should identify default mime type from serializer", function() {
					var serializer = new core.nativeJsonSerializer();
					var meta = getMetadata(serializer);

					var isDefault = false;
					for (var func in meta.functions) {
						if (func.name == "getAsJson") {
							if (structKeyExists(func, "taffy:default")) {
								isDefault = func["taffy:default"];
							} else if (structKeyExists(func, "taffy_default")) {
								isDefault = func["taffy_default"];
							}
							break;
						}
					}
					expect(isDefault).toBeTrue();
				});

			});

			describe("Version", function() {

				it("should report version 4.0.0", function() {
					expect(application._taffy.version).toBe("4.0.0");
				});

			});

			describe("Unhandled paths regex", function() {

				it("should convert unhandledPaths to regex", function() {
					expect(structKeyExists(settings, "unhandledPathsRegex")).toBeTrue();
					expect(len(settings.unhandledPathsRegex)).toBeGT(0);
				});

				it("should match the default /flex2gateway path", function() {
					expect(reFindNoCase("^(" & settings.unhandledPathsRegex & ")", "/flex2gateway")).toBeGT(0);
				});

			});

			describe("Content types", function() {

				it("should have registered supported content types", function() {
					expect(structKeyExists(application._taffy, "contentTypes")).toBeTrue();
					expect(application._taffy.contentTypes).toBeStruct();
				});

			});

		});

	}

}
