import SwiftUI
import WebKit

/// SwiftUI/AttributedString 没有 LaTeX 排版能力。该视图仅使用 Apple 的 WKWebView
/// 展示只读题目文字，并由 KaTeX 渲染 $...$、$$...$$、\(...\) 和 \[...\] 公式。
struct MistakeQuestionTextView: View {
    let text: String
    var maximumHeight: CGFloat? = nil

    @State private var contentHeight: CGFloat = 44

    @ViewBuilder
    var body: some View {
        if MistakeQuestionHTML.containsFormula(in: text) {
            MistakeQuestionWebView(
                text: text,
                contentHeight: $contentHeight
            )
            .frame(height: min(max(contentHeight, 24), maximumHeight ?? .infinity))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
        } else {
            Text(text)
                .lineLimit(maximumHeight == nil ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MistakeQuestionWebView: UIViewRepresentable {
    let text: String
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
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
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onHeightMeasured = { height in
            let normalized = ceil(height)
            guard abs(contentHeight - normalized) > 1 else { return }
            contentHeight = normalized
        }
        context.coordinator.load(text: text, into: webView)
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
        static let heightMessageName = "paperClipMistakeHeight"

        var onHeightMeasured: ((CGFloat) -> Void)?
        private var loadedText: String?

        func load(text: String, into webView: WKWebView) {
            guard loadedText != text else { return }
            loadedText = text
            let resourceURL = Bundle.main.url(
                forResource: "KaTeX",
                withExtension: "bundle"
            )
            webView.loadHTMLString(
                MistakeQuestionHTML.document(for: text),
                baseURL: resourceURL
            )
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.heightMessageName,
                  let height = message.body as? NSNumber
            else { return }
            onHeightMeasured?(CGFloat(truncating: height))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType != .linkActivated else {
                decisionHandler(.cancel)
                return
            }
            let scheme = navigationAction.request.url?.scheme?.lowercased()
            decisionHandler(
                scheme == nil || scheme == "about" || scheme == "file" ? .allow : .cancel
            )
        }
    }
}
