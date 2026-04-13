<cfscript>
/* OpenDataLoader PDF POC
	Docs: https://opendataloader.org/docs/quick-start-java
	Config Javadoc: https://javadoc.io/doc/org.opendataloader/opendataloader-pdf-core/latest/org/opendataloader/pdf/api/Config.html
*/

// Scan samples/pdf/ for PDF files
appDir = getDirectoryFromPath(getCurrentTemplatePath());
samplesDir = appDir & "samples/pdf/";
pdfFiles = directoryList(samplesDir, true, "path", "*.pdf");

// Build relative paths for display
pdfOptions = [];
for (fullPath in pdfFiles) {
	relPath = replace(fullPath, "\", "/", "all");
	relPath = replaceNoCase(relPath, replace(samplesDir, "\", "/", "all"), "");
	arrayAppend(pdfOptions, relPath);
}
arraySort(pdfOptions, "text");

// Check JAR exists
jarPath = appDir & "JARs/opendataloader-pdf-cli-2.2.1.jar";
jarExists = fileExists(jarPath);

// Processing state
result = {};
errorMessage = "";
jTrue = javacast("boolean", true);

if (structKeyExists(form, "btnConvert") && jarExists) {
	try {
		pdfRelPath = form.pdfFile;
		selectedFormats = structKeyExists(form, "outputFormat") ? listToArray(form.outputFormat) : [];
		pdfAbsPath = samplesDir & replace(pdfRelPath, "/", "\", "all");

		// Validate path stays within samples directory
		if (!pdfAbsPath.startsWith(samplesDir) || find("..", pdfAbsPath)) {
			throw(message="Invalid PDF path");
		}

		if (!arrayLen(selectedFormats)) {
			throw(message="Please select at least one output format.");
		}

		// Create timestamped output folder
		pdfBaseName = listFirst(getFileFromPath(pdfRelPath), ".");
		timestamp = dateFormat(now(), "yyyymmdd") & "_" & timeFormat(now(), "HHnnss");
		outputDir = appDir & "output/" & pdfBaseName & "_" & timestamp & "/";
		if (!directoryExists(appDir & "output/")) {
			directoryCreate(appDir & "output/");
		}
		directoryCreate(outputDir);

		// Configure OpenDataLoader
		config = createObject("java", "org.opendataloader.pdf.api.Config").init();
		config.setOutputFolder(outputDir);
		jFalse = javacast("boolean", false);

		// Disable all formats first (JSON is on by default)
		config.setGenerateJSON(jFalse);
		config.setGenerateText(jFalse);
		config.setGenerateHtml(jFalse);
		config.setGeneratePDF(jFalse);
		config.setGenerateMarkdown(jFalse);
		config.setAddImageToMarkdown(jFalse);
		config.setUseHTMLInMarkdown(jFalse);
		config.setImageOutput(config.IMAGE_OUTPUT_OFF);

		// Enable only selected formats
		for (fmt in selectedFormats) {
			switch (fmt) {
				case "json":
					config.setGenerateJSON(jTrue);
					break;
				case "text":
					config.setGenerateText(jTrue);
					break;
				case "html":
					config.setGenerateHtml(jTrue);
					break;
				case "pdf":
					config.setGeneratePDF(jTrue);
					break;
				case "markdown":
					config.setGenerateMarkdown(jTrue);
					break;
				case "markdown-with-html":
					config.setGenerateMarkdown(jTrue);
					config.setUseHTMLInMarkdown(jTrue);
					break;
				case "markdown-with-images":
					config.setGenerateMarkdown(jTrue);
					config.setAddImageToMarkdown(jTrue);
					config.setImageOutput(config.IMAGE_OUTPUT_EXTERNAL);
					break;
			}
		}

		// Apply optional settings
		if (structKeyExists(form, "pages") && len(trim(form.pages))) {
			config.setPages(tostring(trim(form.pages)));
		}
		if (structKeyExists(form, "tableMethod")) {
			config.setTableMethod(tostring(form.tableMethod));
		}
		if (structKeyExists(form, "readingOrder")) {
			config.setReadingOrder(tostring(form.readingOrder));
		}
		if (structKeyExists(form, "keepLineBreaks")) {
			config.setKeepLineBreaks(jTrue);
		}
		if (structKeyExists(form, "includeHeaderFooter")) {
			config.setIncludeHeaderFooter(jTrue);
		}

		// Process the file and measure duration
		startTick = getTickCount();
		OpenDataLoaderPDF = createObject("java", "org.opendataloader.pdf.api.OpenDataLoaderPDF");
		OpenDataLoaderPDF.processFile(tostring(pdfAbsPath), config);
		durationMs = getTickCount() - startTick;

		// Find generated output files
		outputFiles = directoryList(outputDir, false, "path");
		if (arrayLen(outputFiles) gt 0) {
			sourceFileInfo = getFileInfo(pdfAbsPath);
			result = [
				"outputDir": outputDir,
				"outputDirRelative": "output/" & pdfBaseName & "_" & timestamp & "/",
				"durationMs": durationMs,
				"sourceFile": pdfRelPath,
				"sourcePath": "samples/pdf/" & pdfRelPath,
				"sourceSize": sourceFileInfo.size,
				"files": []
			];
			for (f in outputFiles) {
				fileName = getFileFromPath(f);
				ext = listLast(fileName, ".");
				content = "";
				fileInfo = getFileInfo(f);
				// Read text-based output for inline preview
				if (listFindNoCase("json,txt,html,md,markdown", ext)) {
					content = fileRead(f, "utf-8");
				}
				arrayAppend(result.files, [
					"name": fileName,
					"path": f,
					"relativePath": result.outputDirRelative & fileName,
					"extension": ext,
					"content": content,
					"fileSize": fileInfo.size
				]);
			}
		} else {
			errorMessage = "Processing completed but no output files were generated.";
		}

	} catch (any e) {
		errorMessage = "Error processing PDF: " & e.message;
		if (len(e.detail)) {
			errorMessage &= " - " & e.detail;
		}
	}
}

// Output format definitions
formats = [
	[ "value": "json",                 "label": "JSON" ],
	[ "value": "text",                 "label": "Text" ],
	[ "value": "html",                 "label": "HTML" ],
	[ "value": "pdf",                  "label": "PDF (annotated)" ],
	[ "value": "markdown",             "label": "Markdown" ],
	[ "value": "markdown-with-html",   "label": "Markdown with HTML" ],
	[ "value": "markdown-with-images", "label": "Markdown with Images" ]
];
</cfscript>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>OpenDataLoader PDF POC</title>
	<style>
		body { font-family: Arial, sans-serif; max-width: 900px; margin: 20px auto; padding: 0 20px; }
		h1 { color: #333; }
		form { background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
		label { display: block; margin-top: 12px; font-weight: bold; }
		select, input[type="text"] { width: 100%; padding: 8px; margin-top: 4px; box-sizing: border-box; }
		.optional-fields { margin-top: 16px; padding-top: 16px; border-top: 1px solid #ddd; }
		.optional-fields h3 { margin-top: 0; color: #666; }
		.checkbox-row { margin-top: 8px; }
		.checkbox-row label { display: inline; font-weight: normal; margin-left: 4px; }
		.inline-group { display: flex; gap: 16px; }
		.inline-group > div { flex: 1; }
		button { margin-top: 16px; padding: 10px 24px; background: #0066cc; color: #fff; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
		button:hover { background: #0052a3; }
		button:disabled { background: #999; cursor: not-allowed; }
		.error { background: #fee; border: 1px solid #c00; padding: 12px; border-radius: 4px; color: #c00; }
		.result { margin-top: 20px; }
		.result pre { background: #f8f8f8; border: 1px solid #ddd; padding: 16px; overflow-x: auto; max-height: 600px; overflow-y: auto; }
		.format-checkboxes { margin-top: 4px; }
		.duration { font-size: 14px; color: #666; margin-bottom: 16px; }
		.download-link { display: inline-block; margin: 8px 0; padding: 6px 12px; background: #28a745; color: #fff; text-decoration: none; border-radius: 4px; }
		.file-size { color: #888; font-size: 13px; margin-left: 8px; }
		.processing-msg { margin-top: 8px; color: #0066cc; font-weight: bold; }
		.render-md-btn { margin-bottom: 8px; padding: 6px 12px; background: #6f42c1; color: #fff; border: none; border-radius: 4px; cursor: pointer; font-size: 13px; }
		.render-md-btn:hover { background: #5a32a3; }
		iframe { width: 100%; height: 600px; border: 1px solid #ddd; }
		object { width: 100%; height: 600px; }
	</style>
</head>
<body>
	<h1>OpenDataLoader PDF Converter</h1>

	<cfif !jarExists>
		<div class="error">
			<strong>JAR not found.</strong> The OpenDataLoader JAR is missing from <code>JARs/</code>.<br>
			Download it:
			<pre>curl -L "https://github.com/opendataloader-project/opendataloader-pdf/releases/download/v2.2.1/opendataloader-pdf-cli-2.2.1.zip" -o JARs/opendataloader-pdf-cli-2.2.1.zip
unzip -o JARs/opendataloader-pdf-cli-2.2.1.zip "opendataloader-pdf-cli-2.2.1.jar" -d JARs/
rm JARs/opendataloader-pdf-cli-2.2.1.zip</pre>
			Then restart the server.
		</div>
	</cfif>

	<cfoutput>
	<form method="post" action="index.cfm">
		<label for="pdfFile">Select PDF:</label>
		<select name="pdfFile" id="pdfFile" required>
			<option value="">-- Choose a PDF --</option>
			<cfloop array="#pdfOptions#" item="opt">
				<option value="#encodeForHTMLAttribute(opt)#"
					<cfif structKeyExists(form, "pdfFile") && form.pdfFile eq opt>selected</cfif>
				>#encodeForHTML(opt)#</option>
			</cfloop>
		</select>

		<label>Output Format(s):</label>
		<div class="format-checkboxes">
			<cfloop array="#formats#" item="fmt">
				<div class="checkbox-row">
					<input type="checkbox" name="outputFormat" id="fmt_#fmt.value#" value="#fmt.value#"
						<cfif structKeyExists(form, "outputFormat") && listFindNoCase(form.outputFormat, fmt.value)>checked</cfif>>
					<label for="fmt_#fmt.value#">#fmt.label#</label>
				</div>
			</cfloop>
		</div>

		<div class="optional-fields">
			<h3>Optional Settings</h3>

			<label for="pages">Pages (e.g. 1-3,5):</label>
			<input type="text" name="pages" id="pages"
				value="<cfif structKeyExists(form, 'pages')>#encodeForHTMLAttribute(form.pages)#</cfif>"
				placeholder="Leave blank for all pages">

			<div class="inline-group">
				<div>
					<label for="tableMethod">Table Method:</label>
					<select name="tableMethod" id="tableMethod">
						<option value="default" <cfif structKeyExists(form, "tableMethod") && form.tableMethod eq "default">selected</cfif>>Default</option>
						<option value="cluster" <cfif structKeyExists(form, "tableMethod") && form.tableMethod eq "cluster">selected</cfif>>Cluster</option>
					</select>
				</div>
				<div>
					<label for="readingOrder">Reading Order:</label>
					<select name="readingOrder" id="readingOrder">
						<option value="off" <cfif structKeyExists(form, "readingOrder") && form.readingOrder eq "off">selected</cfif>>Off</option>
						<option value="xycut" <cfif structKeyExists(form, "readingOrder") && form.readingOrder eq "xycut">selected</cfif>>XY-Cut</option>
					</select>
				</div>
			</div>

			<div class="checkbox-row">
				<input type="checkbox" name="keepLineBreaks" id="keepLineBreaks" value="true"
					<cfif structKeyExists(form, "keepLineBreaks")>checked</cfif>>
				<label for="keepLineBreaks">Keep Line Breaks</label>
			</div>

			<div class="checkbox-row">
				<input type="checkbox" name="includeHeaderFooter" id="includeHeaderFooter" value="true"
					<cfif structKeyExists(form, "includeHeaderFooter")>checked</cfif>>
				<label for="includeHeaderFooter">Include Header/Footer</label>
			</div>
		</div>

		<input type="hidden" name="btnConvert" value="true">
		<button type="submit" id="btnConvert">Convert</button>
		<div id="processingMsg" class="processing-msg" style="display:none;">Processing... please wait.</div>
	</form>
	</cfoutput>

	<script>
	document.getElementById("btnConvert").closest("form").addEventListener("submit", function() {
		var btn = document.getElementById("btnConvert");
		var msg = document.getElementById("processingMsg");
		btn.disabled = true;
		btn.textContent = "Processing...";
		msg.style.display = "block";
	});

	function renderMarkdown(btn) {
		var pre = btn.nextElementSibling;
		var mdText = pre.textContent;
		var basePath = btn.getAttribute("data-basepath");
		var baseUrl = window.location.href.replace(/[^\/]*$/, "") + basePath;
		var win = window.open("", "_blank");
		win.document.write("<!DOCTYPE html><html><head><meta charset='utf-8'><title>Markdown Preview</title>"
			+ "<base href='" + baseUrl + "'>"
			+ "<script src='https://cdn.jsdelivr.net/npm/markdown-it/dist/markdown-it.min.js'><\/script>"
			+ "<style>body{font-family:Arial,sans-serif;max-width:900px;margin:20px auto;padding:0 20px;line-height:1.6;}"
			+ "pre{background:#f5f5f5;padding:16px;border-radius:4px;overflow-x:auto;}"
			+ "code{background:#f5f5f5;padding:2px 4px;border-radius:3px;}"
			+ "table{border-collapse:collapse;width:100%;}th,td{border:1px solid #ddd;padding:8px;text-align:left;}"
			+ "th{background:#f5f5f5;}img{max-width:100%;}</style></head>"
			+ "<body><div id='content'></div>"
			+ "<script>var md=window.markdownit();document.getElementById('content').innerHTML=md.render(decodeURIComponent('"
			+ encodeURIComponent(mdText) + "'));<\/script></body></html>");
		win.document.close();
	}
	</script>

	<cfif len(errorMessage)>
		<div class="error"><cfoutput>#encodeForHTML(errorMessage)#</cfoutput></div>
	</cfif>

	<cfif !structIsEmpty(result)>
		<div class="result">
			<h2>Result</h2>
			<cfoutput>
			<p class="duration">Processed in <strong>#result.durationMs#ms</strong> (#numberFormat(result.durationMs / 1000, "0.00")#s)</p>
			<p>Source: <a href="#encodeForHTMLAttribute(result.sourcePath)#" target="_blank">#encodeForHTML(result.sourceFile)#</a>
				<span class="file-size">
					<cfif result.sourceSize gte 1048576>
						#numberFormat(result.sourceSize / 1048576, "0.00")# MB
					<cfelseif result.sourceSize gte 1024>
						#numberFormat(result.sourceSize / 1024, "0.0")# KB
					<cfelse>
						#result.sourceSize# bytes
					</cfif>
				</span>
			</p>
			<cfloop array="#result.files#" item="file">
				<h3>#encodeForHTML(file.name)#</h3>

				<!--- Download link with file size --->
				<a class="download-link" href="#encodeForHTMLAttribute(file.relativePath)#" download>Download #encodeForHTML(file.name)#</a>
				<span class="file-size">
					<cfif file.fileSize gte 1048576>
						#numberFormat(file.fileSize / 1048576, "0.00")# MB
					<cfelseif file.fileSize gte 1024>
						#numberFormat(file.fileSize / 1024, "0.0")# KB
					<cfelse>
						#file.fileSize# bytes
					</cfif>
				</span>

				<!--- Inline preview based on file extension --->
				<cfswitch expression="#file.extension#">

					<cfcase value="json">
						<pre>#encodeForHTML(file.content)#</pre>
					</cfcase>

					<cfcase value="txt">
						<pre>#encodeForHTML(file.content)#</pre>
					</cfcase>

					<cfcase value="md,markdown">
						<button type="button" class="render-md-btn" data-basepath="#encodeForHTMLAttribute(result.outputDirRelative)#" onclick="renderMarkdown(this)">Render as HTML</button>
						<pre class="md-source">#encodeForHTML(file.content)#</pre>
					</cfcase>

					<cfcase value="html,htm">
						<iframe src="#encodeForHTMLAttribute(file.relativePath)#"></iframe>
					</cfcase>

					<cfcase value="pdf">
						<object data="#encodeForHTMLAttribute(file.relativePath)#" type="application/pdf" width="100%" height="600px">
							<p>PDF preview not supported in this browser. Use the download link above.</p>
						</object>
					</cfcase>

				</cfswitch>

			</cfloop>
			</cfoutput>
		</div>
	</cfif>

</body>
</html>
