import SwiftUI

extension DiaryEntryDetailPane {
    var isExtracting: Bool {
        extractionTaskSlot.isRunning
    }

    var isBatchAnalyzing: Bool {
        batchAnalysisTaskSlot.isRunning
    }

    func readOnlyView(_ snapshot: DiaryKnowledgeSnapshot) -> some View {
        DiaryEntryReadOnlyContent(
            entry: entry,
            snapshot: snapshot,
            onDelete: { showDeleteConfirm = true },
            onClearKnowledge: { showClearCardsConfirm = true },
            onStartDrafting: startDrafting,
            onEdit: {
                editContent.replace(with: entry)
                phase = .editing
            }
        )
    }

    var editView: some View {
        Form {
            DiaryEntryEditorSections(content: $editContent)
        }
        .navigationTitle(entry.date.formatted(.dateTime.year().month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .prominentSaveToolbar(
            onCancel: { phase = .readOnly },
            onSave: saveEdits
        )
    }

    func draftingView(_ snapshot: DiaryKnowledgeSnapshot) -> some View {
        DiaryDraftingContent(
            snapshot: snapshot,
            isExtracting: isExtracting,
            isBatchAnalyzing: isBatchAnalyzing,
            extractError: extractError,
            onBack: { phase = .readOnly },
            onRestartExtraction: startDrafting,
            onReExtract: { reExtract(source: $0) },
            onBatchAnalyze: batchAnalyze,
            onConfirmAllDrafts: confirmAllDrafts
        )
    }
}
