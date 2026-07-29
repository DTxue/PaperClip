import Foundation

enum VocabularyAnswerMatchPolicy {
    case spelling
    case englishDefinition

    func normalized(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        switch self {
        case .spelling:
            return trimmed.folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
        case .englishDefinition:
            return trimmed.lowercased(with: Locale(identifier: "en_US_POSIX"))
        }
    }
}

enum VocabularyGradingPolicy {
    static func validated(
        _ result: VocabularyGradingResult,
        expectedAnswers: [String],
        hasVisibleAnswers: [Bool],
        matchPolicy: VocabularyAnswerMatchPolicy = .spelling
    ) -> VocabularyGradingResult {
        var itemByIndex: [Int: VocabularyGradingItem] = [:]
        for item in result.items
        where hasVisibleAnswers.indices.contains(item.index - 1)
            && itemByIndex[item.index] == nil {
            itemByIndex[item.index] = item
        }

        let items = hasVisibleAnswers.indices.map { offset in
            let index = offset + 1
            guard hasVisibleAnswers[offset] else {
                return VocabularyGradingItem.unanswered(index: index)
            }
            guard expectedAnswers.indices.contains(offset) else {
                return VocabularyGradingItem.missingExpectedAnswer(index: index)
            }
            guard let item = itemByIndex[index] else {
                return VocabularyGradingItem.missing(index: index)
            }
            return validated(
                item,
                expectedAnswer: expectedAnswers[offset],
                matchPolicy: matchPolicy
            )
        }
        return VocabularyGradingResult(items: items)
    }

    private static func validated(
        _ item: VocabularyGradingItem,
        expectedAnswer: String,
        matchPolicy: VocabularyAnswerMatchPolicy
    ) -> VocabularyGradingItem {
        let recognizedText = item.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recognizedText.isEmpty else {
            return VocabularyGradingItem(
                index: item.index,
                isCorrect: false,
                comment: "未识别到答案",
                recognizedText: ""
            )
        }

        let isCorrect = matchPolicy.normalized(recognizedText) == matchPolicy.normalized(expectedAnswer)
        return VocabularyGradingItem(
            index: item.index,
            isCorrect: isCorrect,
            comment: isCorrect
                ? "正确"
                : mismatchComment(
                    item.comment,
                    expectedAnswer: expectedAnswer,
                    matchPolicy: matchPolicy
                ),
            recognizedText: recognizedText
        )
    }

    private static func mismatchComment(
        _ aiComment: String,
        expectedAnswer: String,
        matchPolicy: VocabularyAnswerMatchPolicy
    ) -> String {
        if matchPolicy == .englishDefinition {
            return "答案应为 \(expectedAnswer)"
        }
        let comment = aiComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !comment.isEmpty,
           VocabularyAnswerMatchPolicy.spelling.normalized(comment)
            != VocabularyAnswerMatchPolicy.spelling.normalized("正确") {
            return comment
        }
        return "答案应为 \(expectedAnswer)"
    }
}

extension VocabularyGradingItem {
    init(
        index: Int,
        isCorrect: Bool,
        comment: String,
        recognizedText: String
    ) {
        self.index = index
        self.isCorrect = isCorrect
        self.comment = comment
        self.recognizedText = recognizedText
    }

    static func unanswered(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "未作答",
            recognizedText: ""
        )
    }

    static func missing(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "批改结果缺失",
            recognizedText: ""
        )
    }

    static func missingExpectedAnswer(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "标准答案缺失",
            recognizedText: ""
        )
    }
}
