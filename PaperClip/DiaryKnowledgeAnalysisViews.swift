import SwiftUI

struct DiaryKnowledgeAnalysisView: View {
    let item: KnowledgeItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !item.subject.isEmpty {
                Label(item.subject, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.indigo)
            }
            if !item.aiEssence.isEmpty { analysisField("本质", item.aiEssence) }
            if !item.aiFormula.isEmpty { analysisField("公式/规律", item.aiFormula) }
            if !item.aiSolutionPath.isEmpty { analysisField("解题路径", item.aiSolutionPath) }
            if !item.aiTrap.isEmpty { analysisField("易错陷阱", item.aiTrap) }
            if !item.aiRelated.isEmpty { analysisField("关联考点", item.aiRelated) }
            if !item.aiMemoryAnchor.isEmpty { analysisField("记忆锚点", item.aiMemoryAnchor) }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.2)) }
    }

    private func analysisField(_ label: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            MarkdownView(text: content)
                .font(.caption)
        }
    }
}

struct DiaryKnowledgeAnalysisProgressView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("AI 解析中…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct DiaryKnowledgeAnalysisFailureView: View {
    let error: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("解析失败", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(error)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("重新解析", action: retry)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(10)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}
