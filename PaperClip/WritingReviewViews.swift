import SwiftUI

struct WritingReviewDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let review: WritingReview
    var onReReview: (() -> Void)? = nil
    private let result: AIWritingReviewResult?

    init(review: WritingReview, onReReview: (() -> Void)? = nil) {
        self.review = review
        self.onReReview = onReReview
        self.result = WritingReviewJSONStorage.decode(review.reviewJSONData)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let result {
                    header(result)
                    textSection("整体评价", result.overallJudgement)
                    textSection("目标标准", result.advancedTargetStandard)
                    if !result.actualLevel.level.isEmpty || !result.actualLevel.reason.isEmpty {
                        textSection("实际水平", "\(result.actualLevel.level)\n\(result.actualLevel.reason)")
                    }
                    textSection("核心差距", result.coreGap)
                    topicAnalysisSection(result.topicTaskAnalysis)
                    abilityDiagnosisSection(result.writingAbilityDiagnosis)
                    listSection("优点", result.strengths)
                    problemSection(result.mainProblems)
                    blueprintSection(result.writingBlueprint)
                    ideaSection(result.ideaUpgrade)
                    contentSection(result.contentAdvice)
                    structureSection(result.structureAdvice)
                    revisedStructurePlanSection(result.revisedStructurePlan)
                    languageSection(result.languageUpgrade)
                    goodWordsSection(result.goodWordsAndSentences)
                    paragraphSection(result.paragraphAdvice ?? [])
                    paragraphReconstructionSection(result.paragraphReconstruction)
                    sampleSection(result.sampleUpgrade)
                    coreSceneUpgradeSection(result.coreSceneUpgrade)
                    studentRevisionTasksSection(result.studentRevisionTasks)
                    listSection("优先修改步骤", result.priorityRevisionPlan)
                    listSection("疑似识别问题", result.possibleOCRIssues)
                    textSection("教师评语", result.teacherComment)
                } else {
                    textSection("批阅结果", String(data: review.reviewJSONData, encoding: .utf8) ?? review.teacherComment)
                }
            }
            .padding()
        }
        .navigationTitle("作文批阅")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if onReReview != nil {
                    Button("重新批阅") {
                        onReReview?()
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }

}
