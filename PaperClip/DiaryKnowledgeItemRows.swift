import SwiftUI
import SwiftData

// MARK: - Draft Knowledge Item Row

struct DraftKnowledgeItemRow: View {
    let item: KnowledgeItem
    @Environment(\.modelContext) var modelContext
    @State var isAnalyzing = false
    @State var analysisError: String? = nil
    @State var summaryDraft = ""
    @State var analysisTaskSlot = ViewTaskSlot()
    @State var alert: AppAlert?
    @FocusState var summaryFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DraftKnowledgeSummaryEditor(
                item: item,
                summaryDraft: $summaryDraft,
                summaryFocused: $summaryFocused,
                onCommit: { _ = commitSummaryDraft() }
            )

            DraftKnowledgeAnalysisContent(
                item: item,
                isAnalyzing: isAnalyzing,
                analysisError: analysisError,
                onRetry: analyze
            )

            DraftKnowledgeItemActions(
                hasAnalysis: item.hasAnalysis,
                isAnalyzing: isAnalyzing,
                onAnalyze: analyze,
                onDelete: deleteItem
            )
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(.quaternary) }
        .onAppear {
            guard summaryDraft.isEmpty else { return }
            summaryDraft = item.summary
        }
        .onDisappear {
            cancelAnalysisTask()
        }
        .appAlert($alert)
    }
}
