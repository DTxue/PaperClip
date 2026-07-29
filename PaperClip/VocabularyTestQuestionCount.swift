import Foundation

enum VocabularyHandwritingTestKind: String, CaseIterable, Identifiable, Sendable {
    case spelling
    case englishDefinition

    var id: String { rawValue }

    func isEligible(englishDefinition: String?) -> Bool {
        switch self {
        case .spelling:
            true
        case .englishDefinition:
            !(englishDefinition?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }

    func prompt(term: String, definition: String) -> String {
        switch self {
        case .spelling:
            definition
        case .englishDefinition:
            term
        }
    }

    func referenceAnswer(term: String, englishDefinition: String?) -> String {
        switch self {
        case .spelling:
            term
        case .englishDefinition:
            englishDefinition ?? ""
        }
    }

    var reviewResponseKind: String {
        switch self {
        case .spelling:
            "测验-手写"
        case .englishDefinition:
            "测验-英文释义手写"
        }
    }

    var reviewDirection: VocabularyDirection {
        switch self {
        case .spelling:
            .definitionToTerm
        case .englishDefinition:
            .termToDefinition
        }
    }
}

enum VocabularyTestMode: String, CaseIterable, Identifiable {
    case regular = "常规"
    case exam = "考试"
    case debug = "调试"

    static let setupModes: [VocabularyTestMode] = [.regular, .debug]
    static let debugQuestionCount = 5

    var id: String { rawValue }

    var minimumRequiredCardCount: Int {
        self == .debug ? Self.debugQuestionCount : 1
    }

    var recordsHistory: Bool {
        self != .debug
    }

    func canStart(cardCount: Int) -> Bool {
        cardCount >= minimumRequiredCardCount
    }

    func resolvedQuestionCount(
        requestedQuestionCount: Int,
        maximumQuestionCount: Int
    ) -> Int {
        if self == .debug {
            return Self.debugQuestionCount
        }
        return VocabularyTestQuestionCount.clamped(
            requestedQuestionCount,
            maximumQuestionCount: maximumQuestionCount
        )
    }
}

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
