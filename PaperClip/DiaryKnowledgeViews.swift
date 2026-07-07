import SwiftUI
import SwiftData

// MARK: - Knowledge Base View

struct KnowledgeItemListRow: View {
    let item: KnowledgeItemListRowData

    private var tagLabel: String? {
        guard let dot = item.subject.firstIndex(of: "·") else { return nil }
        let tag = String(item.subject[item.subject.index(after: dot)...])
        return tag.isEmpty ? nil : tag
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.summary)
                .font(.body)
                .lineLimit(2)
            HStack(spacing: 8) {
                if let tag = tagLabel {
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(item.diaryDate, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct KnowledgeChipCard: View {
    let item: KnowledgeItem
    @State private var showDetail = false

    private var subjectColor: Color {
        switch item.subject {
        case "数学": return .blue
        case "物理": return .cyan
        case "化学": return .green
        case "生物": return .mint
        case "语文": return .orange
        case "历史": return .brown
        case "地理": return .teal
        case "政治": return .red
        case "英语": return .purple
        default: return .indigo
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                if !item.subject.isEmpty {
                    Text(item.subject)
                        .font(.caption2.bold())
                        .foregroundStyle(subjectColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(subjectColor.opacity(0.12), in: Capsule())
                }
                Text(item.summary)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if item.hasAnalysis {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(.quaternary) }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            KnowledgeItemSheetView(item: item)
        }
    }
}
