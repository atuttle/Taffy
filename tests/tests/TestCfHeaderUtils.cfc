component extends="base" {

	function beforeTests() {
		variables.headerUtils = "";
	}

	function setup() {
		// Create fresh instance for each test
		variables.headerUtils = createObject("component", "taffy.core.cfHeaderUtils");
	}

	// Test constructor with no server info (will use actual server scope)
	function test_init_with_no_server_info() {
		var result = variables.headerUtils.init();
		assertEquals(variables.headerUtils, result, "init() should return this");
	}

	// Test constructor with mock server info for CF 2024
	function test_init_with_cf2024_server_info() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2024.0.0"
			}
		};
		
		var result = variables.headerUtils.init(mockServerInfo);
		assertEquals(variables.headerUtils, result, "init() should return this");
		assertEquals(false, result.isColdFusion2025OrLater(), "CF 2024 should not be detected as 2025+");
	}

	// Test constructor with mock server info for CF 2025
	function test_init_with_cf2025_server_info() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2025.0.0"
			}
		};
		
		var result = variables.headerUtils.init(mockServerInfo);
		assertEquals(variables.headerUtils, result, "init() should return this");
		assertEquals(true, result.isColdFusion2025OrLater(), "CF 2025 should be detected as 2025+");
	}

	// Test constructor with mock server info for CF 2026
	function test_init_with_cf2026_server_info() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2026.0.0"
			}
		};
		
		var result = variables.headerUtils.init(mockServerInfo);
		assertEquals(true, result.isColdFusion2025OrLater(), "CF 2026 should be detected as 2025+");
	}

	// Test with Lucee server info (should not be detected as CF 2025+)
	function test_init_with_lucee_server_info() {
		var mockServerInfo = {
			lucee: {
				version: "5.3.8.206"
			},
			coldfusion: {
				productname: "Lucee",
				productversion: "5.3.8"
			}
		};
		
		var result = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, result.isColdFusion2025OrLater(), "Lucee should not be detected as CF 2025+");
	}

	// Test with non-ColdFusion server info
	function test_init_with_non_cf_server_info() {
		var mockServerInfo = {
			os: {
				name: "Windows"
			}
		};
		
		var result = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, result.isColdFusion2025OrLater(), "Non-CF server should not be detected as CF 2025+");
	}

	// Test version detection caching
	function test_version_detection_caching() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2025.0.0"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		
		// First call
		var result1 = util.isColdFusion2025OrLater();
		// Second call should use cached result
		var result2 = util.isColdFusion2025OrLater();
		
		assertEquals(result1, result2, "Cached version detection should return same result");
		assertEquals(true, result1, "CF 2025 should be detected correctly");
	}

	// Test setStatusHeader method (we can't easily test the actual cfheader call, 
	// but we can test that the method executes without error)
	function test_setStatusHeader_with_cf2024() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2024.0.0"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		
		// This should execute without throwing an exception
		// Note: We can't easily test the actual cfheader output in unit tests
		try {
			util.setStatusHeader(500, "Test Error");
			// If we get here, the method executed without error
			assertTrue(true, "setStatusHeader should execute without error for CF 2024");
		} catch (any e) {
			fail("setStatusHeader should not throw exception: " & e.message);
		}
	}

	function test_setStatusHeader_with_cf2025() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2025.0.0"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		
		try {
			util.setStatusHeader(404, "Not Found");
			assertTrue(true, "setStatusHeader should execute without error for CF 2025");
		} catch (any e) {
			fail("setStatusHeader should not throw exception: " & e.message);
		}
	}

	function test_setStatusHeader_without_statustext() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2024.0.0"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		
		try {
			util.setStatusHeader(200);
			assertTrue(true, "setStatusHeader should work without statusText parameter");
		} catch (any e) {
			fail("setStatusHeader should not throw exception when statusText is empty: " & e.message);
		}
	}

	// Test edge case version strings
	function test_version_detection_with_complex_version() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "2025.1.2.3-UPDATE1"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(true, util.isColdFusion2025OrLater(), "Should handle complex version strings");
	}

	// Test version string with text prefix
	function test_version_detection_with_text_prefix() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "ColdFusion 2025"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(true, util.isColdFusion2025OrLater(), "Should extract version from 'ColdFusion 2025' format");
	}

	// Test empty version string
	function test_version_detection_with_empty_version() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: ""
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, util.isColdFusion2025OrLater(), "Empty version should return false");
	}

	// Test non-numeric version string
	function test_version_detection_with_non_numeric_version() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "Latest"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, util.isColdFusion2025OrLater(), "Non-numeric version should return false");
	}

	// Test version with build prefix
	function test_version_detection_with_build_prefix() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "Build 2025.0.0.12345"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(true, util.isColdFusion2025OrLater(), "Should extract version from 'Build 2025...' format");
	}

	// Test malformed version data
	function test_version_detection_with_malformed_data() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "!@#$%"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, util.isColdFusion2025OrLater(), "Malformed version should return false");
	}

	function test_version_detection_with_cf11() {
		var mockServerInfo = {
			coldfusion: {
				productname: "ColdFusion",
				productversion: "11.0.0"
			}
		};
		
		var util = variables.headerUtils.init(mockServerInfo);
		assertEquals(false, util.isColdFusion2025OrLater(), "CF 11 should not be detected as 2025+");
	}


}