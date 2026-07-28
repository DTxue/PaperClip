import Foundation
import SwiftData

struct VocabularyContextPracticeOutput {
    let lesson: VocabularyContextPracticeLesson
}

extension VocabularyContextCardInput {
    init(card: VocabularyCard) {
        self.init(
            cardID: card.id,
            term: card.term,
            definition: card.definition,
            englishDefinition: card.englishDefinition,
            partOfSpeech: card.partOfSpeech,
            example: card.example,
            alternativeAnswers: card.alternativeAnswers
        )
    }
}

enum VocabularyContextPracticeFlow {
    @MainActor
    static func generate(
        deck: VocabularyDeck,
        gradePreset: VocabularyArticleGradePreset,
        maximumCardCount: Int,
        modelContext: ModelContext
    ) async throws -> VocabularyContextPracticeOutput {
        try Task.checkCancellation()
        let cards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
        let states = try modelContext.fetchVocabularyMemoryStates(
            deckID: deck.id,
            direction: .definitionToTerm,
            propertiesToFetch: VocabularyMemoryState.sessionPropertiesToFetch
        )
        let queue = VocabularyStudyQueueBuilder.buildQueue(
            cards: cards,
            states: states,
            deck: deck,
            maximumQueueCount: max(0, maximumCardCount),
            freshSampler: { _, _ in [] }
        )
        guard !queue.isEmpty else {
            throw VocabularyContextPracticeFlowError.noCards
        }

        let inputs = queue.map(VocabularyContextCardInput.init)
        let lesson = try await AIService.generateVocabularyContextPractice(
            cards: inputs,
            configuration: VocabularyContextPromptConfiguration(
                learnerDescription: gradePreset.learnerDescription,
                maximumSentenceWords: gradePreset.maximumSentenceWords
            )
        )
        try Task.checkCancellation()

        return VocabularyContextPracticeOutput(lesson: lesson)
    }
}

enum VocabularyContextPracticeFlowError: LocalizedError {
    case noCards

    var errorDescription: String? {
        switch self {
        case .noCards:
            "当前词集没有可用于语境练习的词条。"
        }
    }
}
