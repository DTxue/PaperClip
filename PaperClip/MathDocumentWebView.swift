import SwiftUI
import WebKit

struct MathDocument {
    let id: String
    let html: String
}

/// 承载 MathJax/HTML 数学内容的 WKWebView。
/// 原生 API 评估：SwiftUI 没有等价的 HTML + MathJax 渲染控件；`Text`/`AttributedString`
/// 无法覆盖现有 LaTeX 预览需求。这里仅桥接 Apple 官方 `WKWebView`，禁用链接跳转，
/// 通过脚本消息回传内容高度，业务职责限定为数学 HTML 展示。
struct MathDocumentWebView: UIViewRepresentable {
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
