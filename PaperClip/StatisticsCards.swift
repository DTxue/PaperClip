import SwiftUI

extension StatisticsView {
    // MARK: - Vocabulary Summary Card
    func vocabularySummaryCard(_ summary: StatisticsVocabularySummary) -> some View {
        StatCard(title: "今日刷子统计", icon: "character.book.closed") {
            if summary.hasSessions {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(summary.rows) { row in
                        vocabularyDeckStatRow(row)
                        if row.id != summary.rows.last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                StatisticsCardEmptyState(
                    title: "暂无刷子数据",
                    systemImage: "character.book.closed",
                    description: "今天完成刷子的学习或测试后，这里会按词集显示学习时间和测试表现。"
                )
            }
        }
    }

    // MARK: - PDF Exam Summary Card
    func pdfExamSummaryCard(_ summary: StatisticsPDFExamSummary) -> some View {
        StatCard(title: "今日 PDF 考试统计", icon: "doc.richtext") {
            if summary.hasAttempts {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(summary.rows) { row in
                        pdfExamStatRow(row)
                        if row.id != summary.rows.last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                StatisticsCardEmptyState(
                    title: "暂无 PDF 考试数据",
                    systemImage: "doc.richtext",
                    description: "今天完成题库内 PDF 考试批阅后，这里会显示做题时间和批阅结果。"
                )
            }
        }
    }

    private func vocabularyDeckStatRow(_ row: StatisticsVocabularyDeckRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(row.deckTitle)
                .font(.headline)
                .lineLimit(2)

            VStack(spacing: 10) {
                vocabularyModeStatRow(
                    title: "学习",
                    duration: row.learningDuration,
                    accuracy: row.learningAccuracy,
                    correctCount: row.learningCorrectCount,
                    incorrectCount: row.learningIncorrectCount,
                    isEmpty: !row.hasLearning
                )
                vocabularyModeStatRow(
                    title: "测验",
                    duration: row.testDuration,
                    accuracy: row.testAccuracy,
                    correctCount: row.testCorrectCount,
                    incorrectCount: row.testIncorrectCount,
                    isEmpty: !row.hasTest
                )
            }
        }
    }

    private func pdfExamStatRow(_ row: StatisticsPDFExamRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(row.title)
                .font(.headline)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("考试")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(VocabularyStudySessionFormat.duration(row.duration))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 0) {
                    vocabularyMetric(
                        value: VocabularyStudySessionFormat.percent(row.accuracy),
                        label: "正确率",
                        color: .accentColor
                    )
                    Spacer()
                    vocabularyMetric(
                        value: "\(row.correctCount)",
                        label: "答对",
                        color: .green
                    )
                    Spacer()
                    vocabularyMetric(
                        value: "\(row.incorrectCount)",
                        label: "答错",
                        color: .red
                    )
                }
            }
            .padding(10)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func vocabularyModeStatRow(
        title: String,
        duration: Double,
        accuracy: Double,
        correctCount: Int,
        incorrectCount: Int,
        isEmpty: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(VocabularyStudySessionFormat.duration(duration))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if isEmpty {
                Text("今日暂无\(title)记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 0) {
                    vocabularyMetric(
                        value: VocabularyStudySessionFormat.percent(accuracy),
                        label: "正确率",
                        color: .accentColor
                    )
                    Spacer()
                    vocabularyMetric(
                        value: "\(correctCount)",
                        label: "答对",
                        color: .green
                    )
                    Spacer()
                    vocabularyMetric(
                        value: "\(incorrectCount)",
                        label: "答错",
                        color: .red
                    )
                }
            }
        }
        .padding(10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func vocabularyMetric(value: Int, label: String, color: Color) -> some View {
        vocabularyMetric(value: "\(value)", label: label, color: color)
    }

    private func vocabularyMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Monthly Trend Card
    func monthlyTrendCard(_ monthlyData: [StatisticsMonthPoint]) -> some View {
        StatCard(title: "每月收录趋势", icon: "calendar") {
            MonthlyTrendChartContent(monthlyData: monthlyData)
        }
    }

    // MARK: - Weak Points Card
    func weakPointsCard(_ topTags: [(tag: String, count: Int)]) -> some View {
        StatCard(title: "薄弱知识点 Top 10", icon: "chart.bar.xaxis.ascending") {
            WeakPointsChartContent(topTags: topTags)
        }
    }

    // MARK: - Practice Activity Card
    func practiceActivityCard(_ practiceWeekData: [StatisticsWeekPoint]) -> some View {
        StatCard(title: "练习活跃度（近 8 周）", icon: "pencil.and.list.clipboard") {
            PracticeActivityChartContent(practiceWeekData: practiceWeekData)
        }
    }
}
