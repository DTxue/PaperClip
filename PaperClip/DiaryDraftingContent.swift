import SwiftUI

struct DiaryDraftingContent: View {
    let snapshot: DiaryKnowledgeSnapshot
    let isExtracting: Bool
    let isBatchAnalyzing: Bool
    let extractError: String?
    let onBack: () -> Void
    let onRestartExtraction: () -> Void
    let onReExtract: (String) -> Void
    let onBatchAnalyze: () -> Void
    let onConfirmAllDrafts: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DiaryDraftAnalysisProgressBar(
                    done: snapshot.draftAnalysisDone,
                    total: snapshot.draftAnalysisTotal
                )
                if isExtracting {
                    DiaryKnowledgeExtractionProgress()
                }
                if let extractError {
                    DiaryKnowledgeExtractionFailure(
                        error: extractError,
                        onRestart: onRestartExtraction
                    )
                }
                DiaryKnowledgeDraftSection(
                    title: "学了什么",
                    systemImage: "book.fill",
                    color: .blue,
                    source: "learned",
                    items: snapshot.learnedDrafts,
                    onReExtract: onReExtract
                )
                DiaryKnowledgeDraftSection(
                    title: "没搞懂的",
                    systemImage: "questionmark.circle.fill",
                    color: .orange,
                    source: "confused",
                    items: snapshot.confusedDrafts,
                    onReExtract: onReExtract
                )

                if !snapshot.hasDrafts && !isExtracting && extractError == nil {
                    ContentUnavailableView(
                        "没有草稿",
                        systemImage: "tray",
                        description: Text("点击「重新提取」重新生成知识点。")
                    )
                }
            }
            .frame(maxWidth: 800, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("知识点整理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("返回", action: onBack)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: onBatchAnalyze) {
                    if isBatchAnalyzing {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("解析中…")
                        }
                    } else {
                        Label("一键解析", systemImage: "sparkles")
                    }
                }
                .disabled(!snapshot.hasDrafts || isExtracting || isBatchAnalyzing)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("确认保存", action: onConfirmAllDrafts)
                    .buttonStyle(.borderedProminent)
                    .disabled(!snapshot.hasDrafts || isExtracting)
            }
        }
    }

}
