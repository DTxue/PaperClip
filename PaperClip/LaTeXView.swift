import SwiftUI
import WebKit

// Apple 当前没有原生 LaTeX 排版组件，因此使用一处集中式 WKWebView。
// 整个解析结果共用一个 WebView，避免按字段创建多个 WebContent 进程。
// WebView 仅承担只读公式排版；导航、滚动、弹窗和业务交互仍由 SwiftUI 管理。
struct AnalysisDocumentView: View {
    let analysis: AIQuestionAnalysis

    @State private var contentHeight: CGFloat = 360

    var body: some View {
        MathDocumentWebView(
            document: .init(
                id: AnalysisHTML.documentID(for: analysis),
                html: AnalysisHTML.build(for: analysis)
            ),
            contentHeight: $contentHeight
        )
        .frame(height: max(contentHeight, 360))
        .accessibilityElement(children: .contain)
    }
}

struct RecognitionPreviewView: View {
    let question: String
    var isEmbedded = false

    @State private var contentHeight: CGFloat = 180

    var body: some View {
        MathDocumentWebView(
            document: .init(
                id: "\(question.hashValue)-\(isEmbedded)",
                html: RecognitionHTML.build(
                    question: question,
                    isEmbedded: isEmbedded
                )
            ),
            contentHeight: $contentHeight
        )
        .frame(height: max(contentHeight, isEmbedded ? 44 : 180))
        .accessibilityLabel(question)
    }
}

private struct MathDocument {
    let id: String
    let html: String
}

private struct MathDocumentWebView: UIViewRepresentable {
    let document: MathDocument
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(
            context.coordinator,
            name: Coordinator.heightMessageName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = false
        webView.isInspectable = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onHeightMeasured = { height in
            let normalized = ceil(height)
            guard abs(contentHeight - normalized) > 1 else { return }
            contentHeight = normalized
        }
        context.coordinator.load(document: document, into: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.heightMessageName
        )
        webView.navigationDelegate = nil
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let heightMessageName = "paperClipHeight"

        var onHeightMeasured: ((CGFloat) -> Void)?
        private var loadedDocumentID: String?

        func load(document: MathDocument, into webView: WKWebView) {
            guard loadedDocumentID != document.id else { return }
            loadedDocumentID = document.id
            webView.loadHTMLString(document.html, baseURL: nil)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.heightMessageName else { return }
            if let height = message.body as? NSNumber {
                onHeightMeasured?(CGFloat(truncating: height))
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (
                WKNavigationActionPolicy
            ) -> Void
        ) {
            decisionHandler(
                navigationAction.navigationType == .linkActivated ? .cancel : .allow
            )
        }
    }
}

private enum RecognitionHTML {
    static func build(question: String, isEmbedded: Bool) -> String {
        let content = isEmbedded
            ? """
              <div class="content embedded-content">\(formatted(question))</div>
              """
            : """
              <section class="recognition">
                <h2 class="section-title">
                  <span class="section-icon" aria-hidden="true">⌗</span>
                  <span>识别结果</span>
                </h2>
                <div class="content">\(formatted(question))</div>
              </section>
              """

        return """
        <!DOCTYPE html>
        <html lang="zh-Hans">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
          <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
          <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
          \(sharedStyle)
        </head>
        <body>
          <main>
            \(content)
          </main>
          \(renderingScript)
        </body>
        </html>
        """
    }
}

private enum AnalysisHTML {
    static func documentID(for analysis: AIQuestionAnalysis) -> String {
        [
            analysis.recognizedQuestion,
            analysis.solutionOverview,
            analysis.finalAnswer,
            analysis.solutionSteps.map(\.title).joined(),
            analysis.solutionSteps.map(\.explanation).joined(),
            analysis.commonMistakes.joined()
        ].joined(separator: "\u{1F}").hashValue.description
    }

    static func build(for analysis: AIQuestionAnalysis) -> String {
        let steps = analysis.solutionSteps.map { step in
            """
            <li>
              <h3>\(escaped(step.title))</h3>
              <div class="content">\(formatted(step.explanation))</div>
            </li>
            """
        }.joined()

        let mistakes = analysis.commonMistakes.map {
            "<li>\(formatted($0))</li>"
        }.joined()

        let mistakesSection = mistakes.isEmpty ? "" : """
        <section>
          <h2 class="section-title">
            <span class="section-icon" aria-hidden="true">!</span>
            <span>易错分析</span>
          </h2>
          <ul class="mistakes">\(mistakes)</ul>
        </section>
        """

        return """
        <!DOCTYPE html>
        <html lang="zh-Hans">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
          <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
          <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
          \(sharedStyle)
        </head>
        <body>
          <main>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">✦</span>
                <span>解题思路</span>
              </h2>
              <div class="content">\(formatted(analysis.solutionOverview))</div>
            </section>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">①</span>
                <span>完整解答</span>
              </h2>
              <ol>\(steps)</ol>
            </section>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">✓</span>
                <span>最终答案</span>
              </h2>
              <div class="content answer">\(formatted(analysis.finalAnswer))</div>
            </section>
            \(mistakesSection)
          </main>
          \(renderingScript)
        </body>
        </html>
        """
    }

}

private let sharedStyle = """
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
  main { display: grid; gap: 20px; }
  section {
    padding: 16px;
    border-radius: 14px;
    background: rgba(255, 255, 255, 0.86);
  }
  .section-title {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 0 0 12px;
    font: -apple-system-title3;
    font-weight: 700;
  }
  .section-icon {
    display: inline-grid;
    place-items: center;
    width: 28px;
    height: 28px;
    border-radius: 8px;
    font-size: 17px;
    color: #2563eb;
    background: rgba(37, 99, 235, 0.12);
  }
  .recognition { box-shadow: 0 1px 0 rgba(0, 0, 0, 0.04); }
  .recognition .content { font-size: 1.03em; line-height: 1.85; }
  .embedded-content { font-size: 1em; line-height: 1.65; }
  h3 {
    margin: 0 0 7px;
    font: -apple-system-headline;
    font-weight: 600;
  }
  ol, ul { margin: 0; padding-left: 1.45em; }
  li + li { margin-top: 16px; }
  .answer { font-weight: 600; color: #075985; }
  .mistakes li::marker { color: #c2410c; }
  .katex-display {
    overflow-x: auto;
    overflow-y: hidden;
    padding: 6px 0;
  }
  @media (prefers-color-scheme: dark) {
    body { color: #ebebf5; }
    section { background: rgba(44, 44, 46, 0.86); }
    .section-icon {
      color: #93c5fd;
      background: rgba(96, 165, 250, 0.18);
    }
    .answer { color: #7dd3fc; }
    .mistakes li::marker { color: #fdba74; }
  }
</style>
"""

private let renderingScript = """
<script>
  (() => {
    const reportHeight = () => {
      window.webkit.messageHandlers.paperClipHeight.postMessage(
        Math.ceil(document.documentElement.scrollHeight)
      );
    };
    const render = () => {
      if (window.renderMathInElement) {
        renderMathInElement(document.body, {
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
    new ResizeObserver(reportHeight).observe(document.documentElement);
    document.addEventListener('DOMContentLoaded', render);
    window.addEventListener('load', render);
    setTimeout(render, 250);
    setTimeout(render, 1200);
  })();
</script>
"""

private func formatted(_ value: String) -> String {
    let html = escaped(value)
        .replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
    return replaceNewlinesOutsideMath(in: html)
}

/// 将换行符（真实 0x0A 或 fixUnescapedBackslashes 后的字面量 \n）替换为 <br>，
/// 但在 $...$ 数学范围内保留，供 KaTeX 识别 \neq 等命令。
private func replaceNewlinesOutsideMath(in text: String) -> String {
    var result = ""
    result.reserveCapacity(text.count + 64)
    var inMath = false
    var i = text.startIndex

    while i < text.endIndex {
        let ch = text[i]
        let next = text.index(after: i)

        if ch == "$" {
            inMath.toggle()
            result.append(ch)
        } else if inMath {
            result.append(ch)
        } else if ch == "\n" {
            result.append(contentsOf: "<br>")
        } else if ch == "\\" && next < text.endIndex && text[next] == "n" {
            // 字面量 \n（来自双重转义后的 JSON 换行符），数学范围外视为换行
            result.append(contentsOf: "<br>")
            i = next
        } else {
            result.append(ch)
        }

        i = text.index(after: i)
    }

    return result
}

private func escaped(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}
