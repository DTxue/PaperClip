import SwiftUI

extension StatisticsView {
    func masteryCard(_ summary: MasteryStatusSummary) -> some View {
        StatCard(title: "掌握状态分布", icon: "checkmark.seal") {
            if summary.hasItems {
                VStack(spacing: 14) {
                    masteryStatsRow(summary)
                    MasteryDistributionBar(summary: summary)
                }
            } else {
                StatisticsCardEmptyState(
                    title: "暂无掌握状态数据",
                    systemImage: "checkmark.seal",
                    description: "收录错题后，这里会显示未掌握、待复习和已掌握的分布。"
                )
            }
        }
    }

    private func statPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func masteryStatsRow(_ summary: MasteryStatusSummary) -> some View {
        HStack(spacing: 0) {
            ForEach(summary.segments, id: \.status) { segment in
                statPill(
                    count: segment.count,
                    label: segment.label,
                    color: segment.status.statisticsTextColor
                )
                Spacer()
            }
            VStack(spacing: 2) {
                Text("\(summary.masteredPercent)%")
                    .font(.title2.bold())
                Text("掌握率")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
