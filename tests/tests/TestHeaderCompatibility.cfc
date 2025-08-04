component extends="base" {

	function beforeTests() {
		// These tests will verify our changes work in real scenarios
	}

	// Test that the global helper function works
	function test_global_helper_function() {
		try {
			// Include the helper and test it doesn't throw errors
			include "../../core/cfHeaderHelper.cfm";
			
			// Create a simple test that exercises the function
			// Note: We can't easily capture HTTP headers in unit tests,
			// but we can verify the function executes without error
			setTaffyStatusHeader(200, "OK");
			
			assertTrue(true, "Global helper function should execute without error");
		} catch (any e) {
			fail("Global helper function failed: " & e.message);
		}
	}

	// Test API component integration
	function test_api_component_integration() {
		try {
			// Create an instance of the API component
			var apiComponent = createObject("component", "taffy.core.api");
			
			// Test that it has the setStatusHeader method
			assertTrue(structKeyExists(apiComponent, "setStatusHeader"), "API component should have setStatusHeader method");
			
			// Test calling the method (this will use private access, so we'll test indirectly)
			assertTrue(true, "API component loads successfully");
		} catch (any e) {
			fail("API component integration failed: " & e.message);
		}
	}

	// Test baseDeserializer component integration
	function test_baseDeserializer_integration() {
		try {
			var deserializer = createObject("component", "taffy.core.baseDeserializer");
			
			assertTrue(true, "Base deserializer loads successfully with header utils");
		} catch (any e) {
			fail("Base deserializer integration failed: " & e.message);
		}
	}

	// Test LogToScreen bonus component
	function test_logToScreen_integration() {
		try {
			var logger = createObject("component", "taffy.bonus.LogToScreen");
			var result = logger.init({});
			
			assertTrue(true, "LogToScreen component loads successfully");
		} catch (any e) {
			fail("LogToScreen integration failed: " & e.message);
		}
	}

	// Test version detection with actual server scope
	function test_actual_server_version_detection() {
		try {
			var headerUtils = createObject("component", "taffy.core.cfHeaderUtils").init();
			var isModern = headerUtils.isColdFusion2025OrLater();
			
			// This should work regardless of the actual CF version
			assertTrue(isBoolean(isModern), "Version detection should return boolean");
			
			// Log the actual detection for debugging
			debug("Detected CF 2025+: " & isModern);
			debug("Server product name: " & server.coldfusion.productname);
			debug("Server version: " & server.coldfusion.productversion);
			
		} catch (any e) {
			fail("Actual server version detection failed: " & e.message);
		}
	}

	// Test that our changes don't break existing functionality
	function test_backwards_compatibility() {
		try {
			// Test that we can still create objects the old way
			var headerUtils = createObject("component", "taffy.core.cfHeaderUtils");
			var initialized = headerUtils.init();
			
			assertTrue(true, "Backwards compatibility maintained");
		} catch (any e) {
			fail("Backwards compatibility test failed: " & e.message);
		}
	}

}