import Foundation

enum VocabularyAnswerChecker {
    static func isCorrect(_ answer: String, for card: VocabularyCard, direction: VocabularyDirection) -> Bool {
        let normalizedAnswer = normalize(answer)
        if direction == .termToDefinition {
            return normalize(card.definition) == normalizedAnswer
        }
        if normalize(card.term) == normalizedAnswer {
            return true
        }
        return card.alternativeAnswers.contains {
            normalize($0) == normalizedAnswer
        }
    }

    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}
