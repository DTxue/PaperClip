import Foundation
import SwiftData

struct VocabularyContextPracticeOutput {
    let lesson: VocabularyContextPracticeLesson
    let cardsByID: [UUID: VocabularyCard]
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

        return VocabularyContextPracticeOutput(
            lesson: lesson,
            cardsByID: Dictionary(
                queue.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        )
    }

    @MainActor
    static func recordAttempt(
        response: String,
        item: VocabularyContextPracticeItem,
        card: VocabularyCard,
        deck: VocabularyDeck,
        sessionID: UUID,
        sessionStartedAt: Date,
        previousItems: [VocabularyStudySessionItem],
        duration: TimeInterval,
        modelContext: ModelContext
    ) throws -> VocabularyStudySessionItem {
        guard item.cardID == card.id else {
            throw VocabularyContextPracticeFlowError.sourceCardMismatch
        }

        let isCorrect = VocabularyContextPracticeAnswerChecker.isCorrect(
            response,
            for: item
        )
        let sessionItem = VocabularyStudySessionItem(
            cardID: card.id,
            prompt: "\(item.definition)\n\(item.cloze)",
            expectedAnswer: item.answer,
            isCorrect: isCorrect,
            recognizedText: response
        )

        do {
            try VocabularyMemoryScheduler.record(
                card: card,
                deck: deck,
                direction: .definitionToTerm,
                rating: isCorrect ? .good : .again,
                responseKind: "语境填空",
                duration: max(0, duration),
                modelContext: modelContext,
                saveImmediately: false
            )
            try VocabularyStudySessionTransaction.recordProgress(
                sessionID: sessionID,
                deckID: deck.id,
                kind: "语境练习",
                startedAt: sessionStartedAt,
                items: previousItems + [sessionItem],
                in: modelContext
            )
            return sessionItem
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

enum VocabularyContextPracticeFlowError: LocalizedError {
    case noCards
    case sourceCardMismatch

    var errorDescription: String? {
        switch self {
        case .noCards:
            "当前词集没有可用于语境练习的词条。"
        case .sourceCardMismatch:
            "练习词条与当前词卡不一致，本次结果没有写入。"
        }
    }
}
