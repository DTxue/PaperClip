import Foundation

enum VocabularyStudySessionItemFactory {
    static func prompt(for card: VocabularyCard, direction: VocabularyDirection) -> String {
        direction == .termToDefinition ? card.term : card.definition
    }

    static func answer(for card: VocabularyCard, direction: VocabularyDirection) -> String {
        direction == .termToDefinition ? card.definition : card.term
    }

    static func makeWordBankAnswer(
        card: VocabularyCard,
        placedWords: [String],
        isCorrect: Bool
    ) -> VocabularyStudySessionItem {
        VocabularyStudySessionItem(
            cardID: card.id,
            prompt: card.definition,
            expectedAnswer: card.term,
            isCorrect: isCorrect,
            recognizedText: placedWords.joined(separator: " "),
            comment: isCorrect ? "正确" : "拼句错误"
        )
    }

    static func makeHandwritingTestAnswer(
        card: VocabularyCard,
        prompt: String? = nil,
        expectedAnswer: String? = nil,
        isCorrect: Bool,
        recognizedText: String,
        comment: String
    ) -> VocabularyStudySessionItem {
        VocabularyStudySessionItem(
            cardID: card.id,
            prompt: prompt ?? card.definition,
            expectedAnswer: expectedAnswer ?? card.term,
            isCorrect: isCorrect,
            recognizedText: recognizedText,
            comment: comment
        )
    }
}
