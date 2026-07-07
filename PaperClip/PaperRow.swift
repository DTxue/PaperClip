import SwiftData
import SwiftUI

struct PaperRow: View {
    @Environment(\.modelContext) private var modelContext
    let document: PDFDocumentRowData
    let onRenamed: () -> Void
    @State private var isRenaming = false
    @State private var draftTitle = ""
    @State private var alert: AppAlert?
    @FocusState private var titleFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundStyle(.red)
                .frame(width: 50, height: 58)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                if isRenaming {
                    TextField("试卷名称", text: $draftTitle)
                        .font(.headline)
                        .focused($titleFocused)
                        .onSubmit { commitRename() }
                        .onChange(of: titleFocused) { _, focused in
                            if !focused { commitRename() }
                        }
                } else {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text(document.metadataText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(document.lastOpenDate, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if !isRenaming {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
        .contextMenu {
            Button("重命名", systemImage: "pencil") {
                startRenaming()
            }
        }
        .appAlert($alert)
    }

    private func startRenaming() {
        draftTitle = document.title
        isRenaming = true
        titleFocused = true
    }

    private func commitRename() {
        guard isRenaming else { return }
        isRenaming = false

        let editDraft = PDFDocumentEditDraft(
            title: draftTitle,
            grade: document.grade,
            semester: document.semester,
            subject: document.subject
        )
        guard editDraft.isRenameCandidate(comparedTo: document.title) else {
            draftTitle = document.title
            return
        }

        do {
            guard let fullDocument = try modelContext.fetchPDFDocument(id: document.id) else {
                alert = AppAlert(title: "无法重命名试卷", message: "该试卷不存在或已被删除。")
                onRenamed()
                return
            }
            fullDocument.title = editDraft.normalizedTitle
            try modelContext.saveOrRollbackIfNeeded()
            onRenamed()
        } catch {
            draftTitle = document.title
            alert = AppAlert(title: "无法重命名试卷", error: error)
        }
    }
}
