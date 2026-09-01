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
    static func loadCached(
        deck: VocabularyDeck,
        gradePreset: VocabularyContextGradePreset,
        maximumCardCount: Int,
        modelContext: ModelContext,
        cacheStore: VocabularyContextPracticeCacheStore = .init()
    ) throws -> VocabularyContextPracticeOutput? {
        let cards = try modelContext.fetchVocabularyCards(deckID: deck.id)
        guard !cards.isEmpty else { return nil }
        let identity = cacheIdentity(
            deckID: deck.id,
            cards: cards.map(VocabularyContextCardInput.init),
            gradePreset: gradePreset,
            maximumCardCount: maximumCardCount
        )
        guard let lesson = cacheStore.load(identity: identity) else { return nil }
        return VocabularyContextPracticeOutput(lesson: lesson)
    }

    @MainActor
    static func generate(
        deck: VocabularyDeck,
        gradePreset: VocabularyContextGradePreset,
        maximumCardCount: Int,
        modelContext: ModelContext,
        cacheStore: VocabularyContextPracticeCacheStore = .init()
    ) async throws -> VocabularyContextPracticeOutput {
        try Task.checkCancellation()
        let cards = try modelContext.fetchVocabularyCards(deckID: deck.id)
        let allInputs = cards.map(VocabularyContextCardInput.init)
        let sourceFingerprint = VocabularyContextPracticeSourceFingerprint.make(
            cards: allInputs
        )
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

        let currentCards = try modelContext.fetchVocabularyCards(deckID: deck.id)
        let currentInputs = currentCards.map(VocabularyContextCardInput.init)
        guard VocabularyContextPracticeSourceFingerprint.make(cards: currentInputs)
                == sourceFingerprint
        else {
            throw VocabularyContextPracticeFlowError.sourceCardsChanged
        }
        try Task.checkCancellation()
        try cacheStore.save(
            lesson,
            identity: cacheIdentity(
                deckID: deck.id,
                cards: currentInputs,
                gradePreset: gradePreset,
                maximumCardCount: maximumCardCount
            )
        )
        return VocabularyContextPracticeOutput(lesson: lesson)
    }

    private static func cacheIdentity(
        deckID: UUID,
        cards: [VocabularyContextCardInput],
        gradePreset: VocabularyContextGradePreset,
        maximumCardCount: Int
    ) -> VocabularyContextPracticeCacheIdentity {
        VocabularyContextPracticeCacheIdentity(
            deckID: deckID,
            sourceFingerprint: VocabularyContextPracticeSourceFingerprint.make(
                cards: cards
            ),
            gradePresetRawValue: gradePreset.rawValue,
            maximumCardCount: maximumCardCount
        )
    }
}

enum VocabularyContextPracticeFlowError: LocalizedError {
    case noCards
    case sourceCardsChanged

    var errorDescription: String? {
        switch self {
        case .noCards:
            "当前词集没有可用于语境练习的词条。"
        case .sourceCardsChanged:
            "生成期间词集内容发生了变化，本次结果没有保存。请重新生成。"
        }
    }
}
