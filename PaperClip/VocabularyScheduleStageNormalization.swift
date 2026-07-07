import Foundation

extension VocabularySchedulingCore {
    static func normalizedStage(_ input: VocabularyScheduleInput) -> String {
        if input.reviewCount <= 0 { return "new" }
        switch input.stage {
        case "learning", "review", "relearning":
            return input.stage
        default:
            return input.algorithmVersion < algorithmVersion ? "review" : "new"
        }
    }
}
