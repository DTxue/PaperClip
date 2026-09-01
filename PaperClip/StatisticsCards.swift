import SwiftUI

extension StatisticsView {
    // MARK: - Vocabulary Summary Card
    func vocabularySummaryCard(_ summary: StatisticsVocabularySummary) -> some View {
        StatCard(title: "今日 ENG 统计", icon: "character.book.closed") {
            if summary.hasSessions {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(summary.rows) { row in
                        vocabularyDeckStatRow(row)
                        if row.id != summary.rows.last?.id {
                            Divider()
                        }
                    }
                }
            } else {
                StatisticsCardEmptyState(
                    title: "暂无 ENG 数据",
                    systemImage: "character.book.closed",
                    description: "今天完成 ENG 英语单词学习或测试后，这里会按词集显示学习时间和测试表现。"
                )
            }
        }
    }

    private func vocabularyDeckStatRow(_ row: StatisticsVocabularyDeckRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row.deckTitle)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            VStack(spacing: 4) {
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

    private func vocabularyModeStatRow(
        title: String,
        duration: Double,
        accuracy: Double,
        correctCount: Int,
        incorrectCount: Int,
        isEmpty: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 30, alignment: .leading)

            if isEmpty {
                Text("暂无")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                compactMetric(
                    value: VocabularyStudySessionFormat.duration(duration),
                    label: "用时",
                    color: .secondary
                )
                Spacer(minLength: 4)
                compactMetric(
                    value: VocabularyStudySessionFormat.percent(accuracy),
                    label: "正确率",
                    color: .accentColor
                )
                compactMetric(value: "\(correctCount)", label: "对", color: .green)
                compactMetric(value: "\(incorrectCount)", label: "错", color: .red)
            }
        }
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

    private func compactMetric(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }

}
