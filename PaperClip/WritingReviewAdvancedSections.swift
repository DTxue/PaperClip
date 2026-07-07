import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func topicAnalysisSection(_ item: AIWritingReviewResult.TopicTaskAnalysis?) -> some View {
        if let item {
            VStack(alignment: .leading, spacing: 10) {
                Text("题目任务分析")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    if !item.keywords.isEmpty {
                        Text("关键词：\(item.keywordsText)")
                            .font(.subheadline.weight(.semibold))
                    }
                    textSection("题目真正写作要求", item.realTask)
                    textSection("审题把握情况", item.studentHandling)
                    textSection("易偏题/写浅的地方", item.riskOfShallowWriting)
                    textSection("高分写作方向", item.bestWritingDirection)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    func abilityDiagnosisSection(_ items: [AIWritingReviewResult.WritingAbilityDiagnosis]?) -> some View {
        if let items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("作文能力诊断书")
                    .font(.headline)
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.ability)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                        Text("原文证据：\(item.evidenceFromEssay)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("得分影响：\(item.impact)")
                        Text("针对性修改建议：\(item.trainingSuggestion)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

}
