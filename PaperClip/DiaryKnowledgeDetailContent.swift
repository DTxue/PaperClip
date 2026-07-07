import SwiftUI

struct KnowledgeItemDetailContent: View {
    let item: KnowledgeItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                analysisContent
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.summary)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                if !item.subject.isEmpty {
                    Label(item.subject, systemImage: "tag.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.indigo)
                }
                Text(item.diaryDate, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var analysisContent: some View {
        if item.hasAnalysis {
            KnowledgeAnalysisSections(item: item)
        } else {
            ContentUnavailableView(
                "暂无 AI 解析",
                systemImage: "brain",
                description: Text("在日记整理流程中可以获取 AI 解析。")
            )
        }
    }
}
