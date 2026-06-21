import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \MistakeCard.createdAt) private var cards: [MistakeCard]
    @Query(sort: \MistakePracticeLayer.createdAt) private var practiceLayers: [MistakePracticeLayer]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.bar",
                        description: Text("完成做题并收录错题后，这里会显示学习进度分析。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 20)], spacing: 20) {
                        masteryCard
                        subjectBreakdownCard
                        monthlyTrendCard
                        weakPointsCard
                        practiceActivityCard
                    }
                }
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("学习统计")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary Stats

    private var masteredCount: Int { cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count }
    private var reviewCount: Int   { cards.filter { $0.status == MasteryStatus.review.rawValue }.count }
    private var unmasteredCount: Int { cards.filter { $0.status == MasteryStatus.unmastered.rawValue }.count }
    private var masteryPct: Double { cards.isEmpty ? 0 : Double(masteredCount) / Double(cards.count) }

    // MARK: - Mastery Distribution Card

    private var masteryCard: some View {
        StatCard(title: "掌握状态分布", icon: "checkmark.seal") {
            VStack(spacing: 14) {
                // 总览数字行
                HStack(spacing: 0) {
                    statPill(count: unmasteredCount, label: "未掌握", color: .red)
                    Spacer()
                    statPill(count: reviewCount, label: "待复习", color: .orange)
                    Spacer()
                    statPill(count: masteredCount, label: "已掌握", color: .green)
                    Spacer()
                    VStack(spacing: 2) {
                        Text("\(Int(masteryPct * 100))%")
                            .font(.title2.bold())
                        Text("掌握率")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 横向分段条
                GeometryReader { proxy in
                    let w = proxy.size.width
                    HStack(spacing: 2) {
                        if unmasteredCount > 0 {
                            Color.red.opacity(0.7)
                                .frame(width: w * CGFloat(unmasteredCount) / CGFloat(cards.count))
                        }
                        if reviewCount > 0 {
                            Color.orange
                                .frame(width: w * CGFloat(reviewCount) / CGFloat(cards.count))
                        }
                        if masteredCount > 0 {
                            Color.green
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .frame(height: 12)
            }
        }
    }

    // MARK: - Subject Breakdown Card

    private var subjectData: [(subject: String, count: Int)] {
        Dictionary(grouping: cards, by: \.subject)
            .map { (subject: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var subjectBreakdownCard: some View {
        StatCard(title: "学科分布", icon: "book.closed") {
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

    // MARK: - Monthly Trend Card

    private struct MonthPoint: Identifiable {
        let month: Date
        let count: Int
        var id: Date { month }
    }

    private var monthlyData: [MonthPoint] {
        let calendar = Calendar.current
        guard let currentMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: .now)
        ) else { return [] }

        return (0..<12).reversed().compactMap { offset in
            guard let month = calendar.date(
                byAdding: .month,
                value: -offset,
                to: currentMonth
            ), let nextMonth = calendar.date(byAdding: .month, value: 1, to: month)
            else { return nil }

            let count = cards.count {
                $0.createdAt >= month && $0.createdAt < nextMonth
            }
            return MonthPoint(month: month, count: count)
        }
    }

    private var monthlyTrendCard: some View {
        StatCard(title: "每月收录趋势", icon: "calendar") {
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
                AxisMarks(values: .stride(by: .month, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - Weak Points Card

    private var topTags: [(tag: String, count: Int)] {
        var freq: [String: Int] = [:]
        for card in cards {
            for tag in card.tags { freq[tag, default: 0] += 1 }
        }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }
    }

    private var weakPointsCard: some View {
        StatCard(title: "薄弱知识点 Top 10", icon: "chart.bar.xaxis.ascending") {
            if topTags.isEmpty {
                Text("暂无知识点标签数据")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
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

    // MARK: - Practice Activity Card

    private struct WeekPoint: Identifiable {
        let week: Date
        let gotIt: Int
        let notYet: Int
        var id: Date { week }
    }

    private var practiceWeekData: [WeekPoint] {
        guard !practiceLayers.isEmpty else { return [] }
        let calendar = Calendar.current
        guard let currentWeek = calendar.dateInterval(
            of: .weekOfYear,
            for: .now
        )?.start else { return [] }

        return (0..<8).reversed().compactMap { offset in
            guard let week = calendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: currentWeek
            ), let nextWeek = calendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: week
            ) else { return nil }

            let layers = practiceLayers.filter {
                $0.createdAt >= week && $0.createdAt < nextWeek
            }
            return WeekPoint(
                week: week,
                gotIt: layers.count { $0.mark == PracticeMark.gotIt.rawValue },
                notYet: layers.count { $0.mark == PracticeMark.notYet.rawValue }
            )
        }
    }

    private var practiceActivityCard: some View {
        StatCard(title: "练习活跃度（近 8 周）", icon: "pencil.and.list.clipboard") {
            if practiceWeekData.isEmpty {
                Text("还没有练习记录")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart {
                    ForEach(practiceWeekData) { pt in
                        BarMark(
                            x: .value("周", pt.week),
                            y: .value("题数", pt.gotIt),
                            stacking: .standard
                        )
                        .foregroundStyle(by: .value("结果", "会了"))
                        BarMark(
                            x: .value("周", pt.week),
                            y: .value("题数", pt.notYet),
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

    // MARK: - Helpers

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
}

// MARK: - Stat Card Container

private struct StatCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(.quaternary)
        }
    }
}
