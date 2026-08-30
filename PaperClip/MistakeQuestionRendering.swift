import Foundation

enum MistakeQuestionHTML {
    static func containsFormula(in text: String) -> Bool {
        text.contains("$")
            || text.contains(#"\("#)
            || text.contains(#"\["#)
    }

    static func document(for questionText: String) -> String {
        let content = escaped(questionText)
            .replacingOccurrences(of: "\n", with: "<br>")

        return """
        <!doctype html>
        <html lang="zh-CN">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; font-src 'self'; img-src data:">
          <link rel="stylesheet" href="katex.min.css">
          <script defer src="katex.min.js"></script>
          <script defer src="contrib/auto-render.min.js"></script>
          <style>
            * { box-sizing: border-box; }
            html, body { margin: 0; padding: 0; background: transparent; }
            body {
              color: #1c1c1e;
              font: -apple-system-body;
              line-height: 1.65;
              overflow-wrap: anywhere;
              -webkit-text-size-adjust: 100%;
            }
            main { padding: 1px 0; }
            .katex-display {
              overflow-x: auto;
              overflow-y: hidden;
              padding: 4px 0;
            }
            @media (prefers-color-scheme: dark) {
              body { color: #f2f2f7; }
            }
          </style>
        </head>
        <body>
          <main id="question">\(content)</main>
          <script>
            (() => {
              const reportHeight = () => {
                const height = Math.max(1, Math.ceil(document.querySelector('main').getBoundingClientRect().height));
                window.webkit.messageHandlers.paperClipMistakeHeight.postMessage(height);
              };
              const render = () => {
                if (window.renderMathInElement) {
                  renderMathInElement(document.getElementById('question'), {
                    delimiters: [
                      {left: '$$', right: '$$', display: true},
                      {left: '$', right: '$', display: false},
                      {left: '\\\\(', right: '\\\\)', display: false},
                      {left: '\\\\[', right: '\\\\]', display: true}
                    ],
                    throwOnError: false
                  });
                }
                reportHeight();
              };
              new ResizeObserver(reportHeight).observe(document.querySelector('main'));
              document.addEventListener('DOMContentLoaded', render);
              window.addEventListener('load', render);
              setTimeout(render, 300);
              setTimeout(render, 1200);
            })();
          </script>
        </body>
        </html>
        """
    }

    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
