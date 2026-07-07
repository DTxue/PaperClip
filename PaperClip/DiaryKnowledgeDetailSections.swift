import SwiftUI

struct KnowledgeAnalysisSections: View {
    let item: KnowledgeItem

    var body: some View {
        if !item.aiEssence.isEmpty {
            detailSection("本质理解", icon: "lightbulb.fill", color: .blue, item.aiEssence)
        }
        if !item.aiFormula.isEmpty {
            detailSection("公式/规律", icon: "function", color: .purple, item.aiFormula)
        }
        if !item.aiSolutionPath.isEmpty {
            detailSection("解题路径", icon: "arrow.right.circle.fill", color: .teal, item.aiSolutionPath)
        }
        if !item.aiTrap.isEmpty {
            detailSection("易错陷阱", icon: "exclamationmark.triangle.fill", color: .orange, item.aiTrap)
        }
        if !item.aiRelated.isEmpty {
            detailSection("关联考点", icon: "arrow.triangle.branch", color: .green, item.aiRelated)
        }
        if !item.aiMemoryAnchor.isEmpty {
            detailSection("记忆锚点", icon: "brain.head.profile", color: .pink, item.aiMemoryAnchor)
        }
    }

    private func detailSection(_ title: String, icon: String, color: Color, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
            MarkdownView(text: content)
                .font(.body)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15)) }
        }
    }
}
