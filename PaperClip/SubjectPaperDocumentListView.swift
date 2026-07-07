import SwiftUI

struct SubjectPaperDocumentListView: View {
    let snapshot: SubjectDocumentSnapshot
    let onOpen: (PDFDocumentRowData) -> Void
    let onRefresh: () -> Void
    let onEdit: (PDFDocumentRowData) -> Void
    let onDelete: (PDFDocumentRowData) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if snapshot.filteredDocuments.isEmpty {
                    emptyState
                } else {
                    documentRows
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(snapshot.documents.isEmpty ? "还没有试卷" : "没有符合条件的试卷", systemImage: "doc")
        } description: {
            Text(
                snapshot.documents.isEmpty
                    ? "点击右上角 + 导入一份 PDF 开始做题。"
                    : "试试调整年级或学期筛选条件。"
            )
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var documentRows: some View {
        LazyVStack(spacing: 12) {
            ForEach(snapshot.filteredDocuments) { document in
                Button {
                    onOpen(document)
                } label: {
                    PaperRow(document: document, onRenamed: onRefresh)
                }
                .buttonStyle(.plain)
                .accessibilityHint("打开试卷")
                .contextMenu {
                    Button("编辑分类", systemImage: "pencil") {
                        onEdit(document)
                    }
                    Divider()
                    Button("删除", systemImage: "trash", role: .destructive) {
                        onDelete(document)
                    }
                }
            }
        }
        .frame(maxWidth: 840)
    }
}
