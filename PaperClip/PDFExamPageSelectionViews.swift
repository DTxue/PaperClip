import SwiftUI

struct PDFExamPageSelectionView: View {
    let documentURL: URL
    let onStart: ([Int]) -> Void

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
                        onPageAppear: { await generateThumbnailIfNeeded(for: $0) }
                    )
                }
            }
            .navigationTitle(snapshot.selectionTitle(emptyTitle: "选择考试页", includesTotal: false))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                PDFExamPageSelectionToolbarContent(
                    snapshot: snapshot,
                    selectedIndices: $selectedIndices,
                    alert: $alert,
                    onCancel: { dismiss() },
                    onStart: onStart
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: documentURL) {
            await loadPageCount()
        }
        .appAlert($alert)
    }
}
