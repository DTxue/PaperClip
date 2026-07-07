import Foundation

enum FormulaChapterHTML {
    static func build(chapter: MathematicsReferenceChapter) -> String {
        let rows = chapter.entries.map { entry in
            """
            <div class="formula-row">
              <div class="formula-title">\(formatted(entry.title))</div>
              <div class="formula-detail">\(formatted(entry.detail))</div>
            </div>
            """
        }.joined()

        return """
        <!DOCTYPE html>
        <html lang="zh-Hans">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
          \(katexResources)
          \(formulaChapterStyle)
        </head>
        <body>
          <main>\(rows)</main>
          \(renderingScript)
        </body>
        </html>
        """
    }
}

let formulaChapterStyle = """
<style>
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: transparent; }
  body {
    font: -apple-system-body;
    line-height: 1.65;
    overflow-wrap: anywhere;
    color: #1c1c1e;
    -webkit-text-size-adjust: 100%;
  }
  main { display: flex; flex-direction: column; }
  .formula-row {
    padding: 13px 18px;
    border-bottom: 0.5px solid rgba(60, 60, 67, 0.18);
  }
  .formula-row:last-child { border-bottom: none; }
  .formula-title {
    font-weight: 600;
    margin-bottom: 4px;
  }
  .formula-detail {
    color: rgba(60, 60, 67, 0.6);
  }
  .katex-display {
    overflow-x: auto;
    overflow-y: hidden;
    padding: 4px 0;
    margin: 4px 0;
  }
  @media (prefers-color-scheme: dark) {
    body { color: #ebebf5; }
    .formula-row { border-bottom-color: rgba(255, 255, 255, 0.15); }
    .formula-detail { color: rgba(235, 235, 245, 0.6); }
  }
</style>
"""
