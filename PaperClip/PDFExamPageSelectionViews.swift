import SwiftUI

struct PDFExamPageSelectionView: View {
    let documentURL: URL
    let decision: PDFExamResumeDecision
    let onContinue: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State var pageCount: Int?
    @State var pageThumbnails: [Int: UIImage] = [:]
    @State var renderingThumbnailIndices: Set<Int> = []
    @State var selectedIndices: Set<Int> = []
    @State var alert: AppAlert?

    var body: some View {
        let snapshot = selectionSnapshot

        NavigationStack {
            Group {
                if pageCount == nil {
                    ProgressView("加载 PDF...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if snapshot.pageCount == 0 {
                    ContentUnavailableView("无页面", systemImage: "doc.slash")
                } else {
                    PDFPageSelectionGrid(
                        pageCount: snapshot.pageCount,
                        selectedIndices: $selectedIndices,
                        style: .thumbnail,
                        thumbnail: { pageThumbnails[$0] },
                        supplement: supplement(for:),
                        isPageEnabled: decision.canSelectForExam(pageIndex:),
                        onPageAppear: { await generateThumbnailIfNeeded(for: $0) }
                    )
                }
            }
            .navigationTitle("继续考试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(continueButtonTitle) {
                        guard let pageIndex = selectedIndices.first else {
                            alert = AppAlert(title: "没有可继续的页面", message: "本轮考试可能已经完成。")
                            return
                        }
                        onContinue(pageIndex)
                    }
                    .disabled(selectedIndices.isEmpty)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Label("已批阅页面不能再次参加本轮考试", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: documentURL) {
            await loadPageCount()
        }
        .appAlert($alert)
    }
}

private extension PDFExamPageSelectionView {
    var continueButtonTitle: String {
        switch decision.target {
        case let .resumeDraft(pageIndex):
            return "继续第 \(pageIndex + 1) 页"
        case let .retryGrading(pageIndex):
            return "重试第 \(pageIndex + 1) 页"
        case let .startNextPage(pageIndex):
            return "开始第 \(pageIndex + 1) 页"
        case .roundCompleted:
            return "本轮已完成"
        }
    }

    func supplement(for pageIndex: Int) -> PDFPageSelectionSupplement? {
        switch decision.state(for: pageIndex) {
        case .graded:
            return PDFPageSelectionSupplement(title: "已批阅", systemImage: "checkmark.seal.fill")
        case .retryGrading:
            return PDFPageSelectionSupplement(title: "待重试", systemImage: "arrow.clockwise.circle")
        case .resumeDraft:
            return PDFPageSelectionSupplement(title: "继续作答", systemImage: "pencil.and.scribble")
        case .ready:
            return PDFPageSelectionSupplement(title: "下一页", systemImage: "play.circle.fill")
        case .locked:
            return PDFPageSelectionSupplement(title: "未解锁", systemImage: "lock.fill")
        case nil:
            return nil
        }
    }
}
