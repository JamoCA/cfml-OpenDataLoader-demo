# CFML OpenDataLoader PDF Demo

A CFML proof-of-concept that uses the [OpenDataLoader](https://opendataloader.org/) Java library to convert PDF documents into multiple structured output formats through an interactive web UI. Compatible with Adobe ColdFusion 2016+, Lucee, and BoxLang.

## What It Does

OpenDataLoader is an open-source (Apache 2.0), GPU-free PDF parsing library optimized for AI/RAG pipelines. This demo shows how to integrate it with ColdFusion using Java interop (`createObject("java", ...)`).

**Supported output formats:**

| Format | Description |
|--------|-------------|
| JSON | Structured data with bounding box coordinates |
| Text | Plain text extraction |
| HTML | Web-ready formatted output |
| PDF | Annotated PDF with detected structure |
| Markdown | Structured markdown |
| Markdown with HTML | Markdown using HTML tags for complex elements |
| Markdown with Images | Markdown with embedded image references |

Multiple formats can be selected and generated in a single conversion.

**Optional settings:**

- Page range selection (e.g. `1-3,5`)
- Table detection method (Default or Cluster)
- Reading order (Off or XY-Cut)
- Keep line breaks
- Include header/footer content

## Requirements

- [CommandBox](https://www.ortussolutions.com/products/commandbox) (CLI & CFML server manager)
- One of the following CFML engines:
  - Adobe ColdFusion 2016 or later
  - [Lucee](https://www.lucee.org/)
  - [BoxLang](https://boxlang.io/)
- Java 8+ (for the OpenDataLoader JAR)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/JamoCA/cfml-OpenDataLoader-demo.git
cd cfml-OpenDataLoader-demo
```

### 2. Download the OpenDataLoader JAR

The fat JAR (~24MB) bundles the core API and all dependencies.

```bash
curl -L "https://github.com/opendataloader-project/opendataloader-pdf/releases/download/v2.2.1/opendataloader-pdf-cli-2.2.1.zip" -o JARs/opendataloader-pdf-cli-2.2.1.zip
unzip -o JARs/opendataloader-pdf-cli-2.2.1.zip "opendataloader-pdf-cli-2.2.1.jar" -d JARs/
rm JARs/opendataloader-pdf-cli-2.2.1.zip
```

### 3. Start the server

```bash
box server start
```

This starts an Adobe ColdFusion 2023 instance via CommandBox (configurable in `server.json`). Open the URL shown in the console.

To use a different engine, edit `server.json`:

```json
{ "app": { "cfengine": "lucee@5" } }
```

```json
{ "app": { "cfengine": "boxlang@1" } }
```

### 4. Convert a PDF

1. Select a sample PDF from the dropdown
2. Check one or more output formats
3. Adjust optional settings if desired
4. Click **Convert**

Results display inline with download links and file sizes. Processing duration is shown at the top of the results.

## How It Works

The integration uses three Java classes from the `org.opendataloader.pdf.api` package:

- **`Config`** -- configures output formats, page ranges, and processing options
- **`OpenDataLoaderPDF`** -- the main entry point; `processFile(path, config)` converts a PDF
- **`FilterConfig`** -- controls content filtering (hidden text, off-page content, etc.)

ColdFusion loads the JAR via `this.javaSettings` in `Application.cfc`:

```cfm
this.javaSettings = {
    loadPaths: [ appDir & "JARs" ],
    loadColdFusionClassPath: true,
    reloadOnChange: false
};
```

Processing a PDF is straightforward:

```cfm
config = createObject("java", "org.opendataloader.pdf.api.Config").init();
config.setOutputFolder(outputDir);
config.setGenerateMarkdown(javacast("boolean", true));

OpenDataLoaderPDF = createObject("java", "org.opendataloader.pdf.api.OpenDataLoaderPDF");
OpenDataLoaderPDF.processFile(tostring(pdfPath), config);
```

## Project Structure

```
cfml-OpenDataLoader-demo/
  Application.cfc    - App config, JAR loading, shutdown hook
  index.cfm          - Single-page UI (form, processing, results)
  server.json        - CommandBox server config (defaults to CF2023)
  JARs/              - OpenDataLoader fat JAR (not in repo, download separately)
  output/            - Generated conversion results (gitignored)
  samples/
    pdf/             - Sample PDFs for testing
```

## Sample PDFs Included

- `lorem.pdf` -- Simple text document
- `1901.03003.pdf` -- Academic paper
- `2408.02509v1.pdf` -- Multi-page research paper
- `chinese_scan.pdf` -- Scanned document with Chinese text
- `issue-336-conto-economico-bialetti.pdf` -- Financial statement (Italian)
- `pdfua-1-reference-suite-1-1/` -- PDF/UA accessibility reference suite (invoices, brochures, forms, etc.)

## Resources

- [OpenDataLoader Documentation](https://opendataloader.org/docs/quick-start-java)
- [Config Javadoc](https://javadoc.io/doc/org.opendataloader/opendataloader-pdf-core/latest/org/opendataloader/pdf/api/Config.html)
- [OpenDataLoader GitHub](https://github.com/opendataloader-project/opendataloader-pdf)
- [CommandBox](https://www.ortussolutions.com/products/commandbox)

## License

This demo is provided as-is for educational purposes. OpenDataLoader is licensed under [Apache 2.0](https://github.com/opendataloader-project/opendataloader-pdf/blob/main/LICENSE).
