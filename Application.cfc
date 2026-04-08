component
	hint="Application configuration"
	output="false"
{

	this.name = "opendataloader-pdf-cli-Demo";
	this.applicationTimeout = createTimeSpan(0, 1, 0, 0);

	variables.appDir = getDirectoryFromPath(getCurrentTemplatePath());
	// variables.parentDir = variables.appDir & "../";

	// Map the parent directory so "new JSONata()" resolves from tests/
	// this.mappings["/jsonata"] = variables.parentDir;

	// Custom tag path for CFC resolution (fallback for older CF)
	/* this.customTagPaths = [
		variables.parentDir
	]; */

	// Load JARs natively via CF's Java settings
	this.javaSettings = {
		loadPaths: [
			variables.appDir & "JARs"
		],
		loadColdFusionClassPath: true,
		reloadOnChange: false
	};

	public void function onApplicationEnd(struct applicationScope) {
		try {
			createObject("java", "org.opendataloader.pdf.api.OpenDataLoaderPDF").shutdown();
		} catch (any e) {
			// Shutdown is best-effort; log but don't throw
		}
	}

}
