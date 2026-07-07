import SwiftUI

struct DiaryDraftAnalysisProgressBar: View {
    let done: Int
    let total: Int

    private var allDone: Bool { total > 0 && done == total }

    var body: some View {
        if total > 0 {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("AI 解析进度", systemImage: allDone ? "checkmark.circle.fill" : "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(allDone ? .green : .accentColor)
                    Spacer()
                    Text("\(done)/\(total) 已解析")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(allDone ? .green : .secondary)
                }
                ProgressView(value: Double(done), total: Double(total))
                    .progressViewStyle(.linear)
                    .tint(allDone ? .green : .accentColor)
            }
            .padding(12)
            .background(
                (allDone ? Color.green : Color.accentColor).opacity(0.06),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
    }
}

struct DiaryKnowledgeExtractionProgress: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("AI 正在提取知识点…")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DiaryKnowledgeExtractionFailure: View {
    let error: String
    let onRestart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提取失败", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(error)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("重新提取", action: onRestart)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(16)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DiaryKnowledgeDraftSection: View {
    let title: String
    let systemImage: String
    let color: Color
    let source: String
    let items: [KnowledgeItem]
    let onReExtract: (String) -> Void

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundStyle(color)
                    Spacer()
                    Button("重新提取") { onReExtract(source) }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }
                ForEach(items) { item in
                    DraftKnowledgeItemRow(item: item)
                }
            }
        }
    }
}
