import Foundation

enum VocabularyStudySessionItemFactory {
    static func prompt(for card: VocabularyCard, direction: VocabularyDirection) -> String {
        direction == .termToDefinition ? card.term : card.definition
    }

    static func answer(for card: VocabularyCard, direction: VocabularyDirection) -> String {
        direction == .termToDefinition ? card.definition : card.term
    }

    static func makeFlashcardReview(
        card: VocabularyCard,
        direction: VocabularyDirection,
        rating: VocabularyReviewRating
    ) -> VocabularyStudySessionItem {
        VocabularyStudySessionItem(
            cardID: card.id,
            prompt: prompt(for: card, direction: direction),
            expectedAnswer: answer(for: card, direction: direction),
            isCorrect: rating.isPassingRecall,
            comment: rating.title
        )
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
        comment: String,
        keepsRecognizedTextForCorrectAnswer: Bool = false
    ) -> VocabularyStudySessionItem {
        VocabularyStudySessionItem(
            cardID: card.id,
            prompt: prompt ?? card.definition,
            expectedAnswer: expectedAnswer ?? card.term,
            isCorrect: isCorrect,
            recognizedText: isCorrect && !keepsRecognizedTextForCorrectAnswer ? "" : recognizedText,
            comment: comment
        )
    }
}
