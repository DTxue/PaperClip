import SwiftUI

struct DraftKnowledgeSummaryEditor: View {
    let item: KnowledgeItem
    @Binding var summaryDraft: String
    let summaryFocused: FocusState<Bool>.Binding
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("知识点摘要")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("知识点摘要", text: $summaryDraft, axis: .vertical)
                .font(.body)
                .lineLimit(2...4)
                .focused(summaryFocused)
                .onSubmit(onCommit)
                .onChange(of: summaryFocused.wrappedValue) { _, focused in
                    if !focused { onCommit() }
                }
            if !item.changeNote.isEmpty {
                Label(item.changeNote, systemImage: "pencil.and.sparkles")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }
        }
    }
}

struct DraftKnowledgeAnalysisContent: View {
    let item: KnowledgeItem
    let isAnalyzing: Bool
    let analysisError: String?
    let onRetry: () -> Void

    var body: some View {
        if item.hasAnalysis {
            DiaryKnowledgeAnalysisView(item: item)
        } else if isAnalyzing {
            DiaryKnowledgeAnalysisProgressView()
        } else if let analysisError {
            DiaryKnowledgeAnalysisFailureView(error: analysisError, retry: onRetry)
        }
    }
}

struct DraftKnowledgeItemActions: View {
    let hasAnalysis: Bool
    let isAnalyzing: Bool
    let onAnalyze: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(hasAnalysis ? "重新解析" : "获取 AI 解析", action: onAnalyze)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isAnalyzing)
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }
}
