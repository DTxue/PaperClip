import SwiftUI
import Charts

struct MonthlyTrendChartContent: View {
    let monthlyData: [StatisticsMonthPoint]

    var body: some View {
        if !monthlyData.contains(where: \.hasEntries) {
            StatisticsCardEmptyState(
                title: "近 12 月没有收录记录",
                systemImage: "calendar",
                description: "收录新的错题后，这里会显示每月变化趋势。"
            )
        } else {
            Chart(monthlyData) { point in
                BarMark(
                    x: .value("月份", point.month, unit: .month),
                    y: .value("数量", point.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.caption2)
                }
            }
        }
    }
}

struct PracticeActivityChartContent: View {
    let practiceWeekData: [StatisticsWeekPoint]

    var body: some View {
        if practiceWeekData.isEmpty {
            StatisticsCardEmptyState(
                title: "近 8 周没有练习记录",
                systemImage: "calendar.badge.clock",
                description: "完成错题练习后，这里会按周统计“会了”和“还不会”。"
            )
        } else {
            Chart {
                ForEach(practiceWeekData) { point in
                    BarMark(
                        x: .value("周", point.week),
                        y: .value("题数", point.gotIt),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("结果", "会了"))
                    BarMark(
                        x: .value("周", point.week),
                        y: .value("题数", point.notYet),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("结果", "还不会"))
                }
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                }
            }
            .chartForegroundStyleScale([
                "会了": Color.green,
                "还不会": Color.red.opacity(0.6)
            ])
        }
    }
}
