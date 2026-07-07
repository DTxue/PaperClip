import SwiftUI
import Charts

struct SubjectBreakdownChartContent: View {
    let subjectData: [(subject: String, count: Int)]

    var body: some View {
        if subjectData.isEmpty {
            StatisticsCardEmptyState(
                title: "暂无学科数据",
                systemImage: "book.closed",
                description: "收录带学科信息的错题后，这里会显示各学科占比。"
            )
        } else {
            Chart(subjectData, id: \.subject) { item in
                SectorMark(
                    angle: .value("数量", item.count),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("学科", item.subject))
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartLegend(position: .trailing, alignment: .center)
        }
    }
}

struct WeakPointsChartContent: View {
    let topTags: [(tag: String, count: Int)]

    var body: some View {
        if topTags.isEmpty {
            StatisticsCardEmptyState(
                title: "暂无知识点标签数据",
                systemImage: "tag",
                description: "给错题添加知识点标签后，这里会显示最需要复习的方向。"
            )
        } else {
            Chart(topTags, id: \.tag) { item in
                BarMark(
                    x: .value("数量", item.count),
                    y: .value("知识点", item.tag)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("×\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: CGFloat(topTags.count) * 26 + 20)
            .chartXAxis(.hidden)
        }
    }
}
