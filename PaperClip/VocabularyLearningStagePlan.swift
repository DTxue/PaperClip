import Foundation

struct VocabularyLearningStagePlan {
    let stage: String
    let steps: [Int]
    let currentStep: Int
}

extension VocabularySchedulingCore {
    static func learningStagePlan(
        oldStage: String,
        input: VocabularyScheduleInput
    ) -> VocabularyLearningStagePlan? {
        switch oldStage {
        case "new":
            VocabularyLearningStagePlan(stage: "learning", steps: learningSteps, currentStep: 0)
        case "learning":
            VocabularyLearningStagePlan(stage: "learning", steps: learningSteps, currentStep: max(0, input.learningStep))
        case "relearning":
            VocabularyLearningStagePlan(stage: "relearning", steps: relearningSteps, currentStep: max(0, input.learningStep))
        default:
            nil
        }
    }
}
