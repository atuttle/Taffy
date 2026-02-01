<cfscript>
/**
 * TestBox Runner for Taffy Framework Tests
 *
 * Run this file via browser or use CommandBox:
 *   box testbox run
 */

// Create TestBox instance
testBox = new testbox.system.TestBox();

// Run all specs in the specs directory
results = testBox.run(
	directory = {
		recurse: true,
		mapping: "tests.specs"
	},
	reporter = url.reporter ?: "simple"
);

// Output the results
writeOutput(results);
</cfscript>
