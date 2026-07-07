import SwiftUI

struct MistakeSourceFilterView: View {
    let sources: [String]
    @Binding var selectedSource: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MistakeFilterHeader(
                title: "来源试卷",
                systemImage: "doc.text",
                clearTitle: "清除",
                clearTint: Color.accentColor,
                isClearVisible: !selectedSource.isEmpty
            ) {
                selectedSource = ""
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sources, id: \.self) { source in
                        sourceButton(source)
                    }
                }
            }
        }
    }

    private func sourceButton(_ source: String) -> some View {
        let isActive = selectedSource == source
        return MistakeFilterChip(
            isActive: isActive,
            activeForeground: .white,
            activeBackground: Color.accentColor,
            horizontalPadding: 14,
            accessibilityLabel: source
        ) {
            selectedSource = isActive ? "" : source
        } content: {
            Text(source)
        }
    }
}

struct MistakeTagFilterView: View {
    let tags: [(tag: String, count: Int)]
    @Binding var selectedTag: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MistakeFilterHeader(
                title: "薄弱知识点",
                systemImage: "chart.bar.xaxis.ascending",
                clearTitle: "清除筛选",
                clearTint: .orange,
                isClearVisible: !selectedTag.isEmpty
            ) {
                selectedTag = ""
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.tag) { item in
                        tagButton(item)
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }

    private func tagButton(_ item: (tag: String, count: Int)) -> some View {
        let isActive = selectedTag == item.tag
        return MistakeFilterChip(
            isActive: isActive,
            activeForeground: .orange,
            activeBackground: Color.orange.opacity(0.12),
            activeStroke: Color.orange.opacity(0.35),
            accessibilityLabel: "\(item.tag)，出错\(item.count)次"
        ) {
            selectedTag = isActive ? "" : item.tag
        } content: {
            HStack(spacing: 5) {
                Text(item.tag)
                Text("×\(item.count)")
                    .foregroundStyle(isActive ? .orange.opacity(0.7) : .secondary)
            }
        }
    }
}
