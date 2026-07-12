import Foundation

enum VocabularyTestQuestionCount {
    static let minimumRatio = 0.6

    static func clamped(_ count: Int) -> Int {
        max(1, count)
    }

    static func minimum(maximumQuestionCount: Int) -> Int {
        let maximumQuestionCount = clamped(maximumQuestionCount)
        return max(1, Int(ceil(Double(maximumQuestionCount) * minimumRatio)))
    }

    static func clamped(_ count: Int, maximumQuestionCount: Int) -> Int {
        let maximumQuestionCount = clamped(maximumQuestionCount)
        return max(minimum(maximumQuestionCount: maximumQuestionCount), min(maximumQuestionCount, count))
    }

    static func selectableRange(maximumQuestionCount: Int) -> ClosedRange<Int> {
        let maximumQuestionCount = clamped(maximumQuestionCount)
        return minimum(maximumQuestionCount: maximumQuestionCount)...maximumQuestionCount
    }

    static func maximum(inBatchCardCounts cardCounts: [Int]) -> Int {
        clamped(cardCounts.reduce(0, +))
    }

    static func allowsSlider(maximumQuestionCount: Int) -> Bool {
        let range = selectableRange(maximumQuestionCount: maximumQuestionCount)
        return range.lowerBound < range.upperBound
    }
}
