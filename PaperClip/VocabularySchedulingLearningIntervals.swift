import Foundation

extension VocabularySchedulingCore {
    static func learningStepOutcome(
        steps: [Int],
        currentStep: Int,
        rating: Int,
        enteringRelearning: Bool = false
    ) -> (minutes: Int, nextStep: Int)? {
        guard !steps.isEmpty, currentStep < steps.count else { return nil }
        if enteringRelearning {
            return rating == 1 ? (steps[currentStep], 0) : nil
        }

        switch rating {
        case 1:
            return (steps[0], 0)
        case 2:
            return (hardLearningMinutes(steps), currentStep)
        case 3:
            let nextStep = currentStep + 1
            guard nextStep < steps.count else { return nil }
            return (steps[nextStep], nextStep)
        default:
            return nil
        }
    }

    private static func hardLearningMinutes(_ steps: [Int]) -> Int {
        if steps.count == 1 {
            return roundedMinutes(Double(steps[0]) * 1.5)
        }
        return roundedMinutes(Double(steps[0] + steps[1]) / 2)
    }

    private static func roundedMinutes(_ value: Double) -> Int {
        Int(value.rounded(.toNearestOrAwayFromZero))
    }
}
