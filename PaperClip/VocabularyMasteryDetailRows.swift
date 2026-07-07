import SwiftUI

struct VocabularyMasteryDirectionView: View {
    let title: String
    let state: VocabularyMemoryState?
    let fsrs: Double
    let weightedResult: VocabularyWeightedMasteryResult
    let mastery: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(VocabularyStudySessionFormat.percent(mastery))
                    .monospacedDigit()
                    .foregroundStyle(VocabularyMasteryStyle.masteryColor(mastery))
            }
            ProgressView(value: mastery)

            if let state {
                VocabularyMemoryStateDetails(state: state)
                Divider()
                VocabularyWeightedMasteryDetails(fsrs: fsrs, weightedResult: weightedResult)
            } else {
                LabeledContent("状态", value: "未学习")
                LabeledContent("下次复习", value: "现在")
            }
        }
    }
}

private struct VocabularyMemoryStateDetails: View {
    let state: VocabularyMemoryState

    var body: some View {
        LabeledContent("状态", value: VocabularyMasteryStyle.stageTitle(state.stage))
        LabeledContent("下次复习") {
            if state.dueDate <= .now {
                Text("已到期")
                    .foregroundStyle(Color.orange)
            } else {
                Text(state.dueDate, format: .dateTime.month().day().hour().minute())
            }
        }
        LabeledContent("稳定度", value: String(format: "%.1f 天", state.stability))
        LabeledContent("难度", value: String(format: "%.1f", state.difficulty))
        LabeledContent("复习次数", value: "\(state.reviewCount)")
        LabeledContent("遗忘次数", value: "\(state.lapseCount)")
    }
}

private struct VocabularyWeightedMasteryDetails: View {
    let fsrs: Double
    let weightedResult: VocabularyWeightedMasteryResult

    var body: some View {
        Group {
            Text("综合熟练度合成明细")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            accuracyRow("闪卡正确率 (15%)", weightedResult.flashcardAccuracy)
            accuracyRow("拼句正确率 (25%)", weightedResult.studyAccuracy)
            accuracyRow("测验正确率 (60%)", weightedResult.quizAccuracy)
            LabeledContent("FSRS 可提取率", value: VocabularyStudySessionFormat.percent(fsrs))
        }
        .font(.footnote)
    }

    private func accuracyRow(_ title: String, _ accuracy: Double?) -> some View {
        LabeledContent(title) {
            if let accuracy {
                Text(VocabularyStudySessionFormat.percent(accuracy))
            } else {
                Text("无历史记录")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
