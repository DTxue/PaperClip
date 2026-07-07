import SwiftUI

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

    @State private var contentHeight: CGFloat

    init(question: String, isEmbedded: Bool = false) {
        self.question = question
        self.isEmbedded = isEmbedded
        _contentHeight = State(initialValue: isEmbedded ? 44 : 180)
    }

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

// MARK: - FormulaChapterView

/// 将一个章节的所有公式条目合并为单个 WebView 渲染，避免每行独立 WebView 的开销。
struct FormulaChapterView: View {
    let chapter: MathematicsReferenceChapter

    @State private var contentHeight: CGFloat = 100

    var body: some View {
        MathDocumentWebView(
            document: .init(
                id: "formula-chapter-\(chapter.id)",
                html: FormulaChapterHTML.build(chapter: chapter)
            ),
            contentHeight: $contentHeight
        )
        .frame(height: max(contentHeight, 44))
        .accessibilityElement(children: .contain)
    }
}
