import SwiftUI
import SwiftData

// MARK: - Entry Detail Pane

struct DiaryEntryDetailPane: View {
    let entry: DiaryEntry
    let onDelete: () -> Void

    @Environment(\.modelContext) var modelContext
    @State var phase: DiaryDetailPhase = .readOnly
    @State var editContent = DiaryEntryEditableContent()
    @State var showDeleteConfirm = false
    @State var showClearCardsConfirm = false
    @State var extractError: String? = nil
    @State var extractionTaskSlot = DiaryTaskSlot()
    @State var batchAnalysisTaskSlot = DiaryTaskSlot()
    @State var alert: AppAlert?

    init(entry: DiaryEntry, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onDelete = onDelete
    }

    var body: some View {
        let knowledgeSnapshot = DiaryKnowledgeSnapshot(items: entry.items)

        Group {
            switch phase {
            case .readOnly: readOnlyView(knowledgeSnapshot)
            case .editing: editView
            case .drafting: draftingView(knowledgeSnapshot)
            }
        }
        .confirmationDialog(
            "删除这篇日记？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) { deleteEntry() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将同时删除所有关联的知识点，无法撤销。")
        }
        .confirmationDialog(
            "清除所有知识点？",
            isPresented: $showClearCardsConfirm,
            titleVisibility: .visible
        ) {
            Button("清除", role: .destructive) {
                if deleteKnowledgeItems(where: { _ in true }) {
                    _ = saveDiaryChanges(alertTitle: "无法清除知识点")
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将清除这篇日记的全部知识点，日记原文不受影响。")
        }
        .onDisappear {
            extractionTaskSlot.cancel()
            batchAnalysisTaskSlot.cancel()
        }
        .appAlert($alert)
    }
}
