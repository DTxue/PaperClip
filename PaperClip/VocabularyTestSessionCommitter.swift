import Foundation
import SwiftData

enum VocabularyTestSessionCommitter {
    @MainActor
    static func commit(
        deck: VocabularyDeck,
        batches: [VocabularyTestBatch],
        handwritingTestKind: VocabularyHandwritingTestKind,
        kind: String,
        startedAt: Date,
        modelContext: ModelContext,
        drawingData: (VocabularyTestBatch, Int) -> Data
    ) throws -> Bool {
        let questionCount = batches.reduce(0) { total, batch in
            total + batch.cards.count
        }
        guard questionCount > 0 else { return false }

        let endedAt = Date.now
        let sessionDuration = endedAt.timeIntervalSince(startedAt)
        let duration = sessionDuration / Double(max(1, questionCount))
        var sessionItems: [VocabularyStudySessionItem] = []
        sessionItems.reserveCapacity(questionCount)

        for batch in batches {
            let itemByIndex = VocabularyTestBatchProjection.gradingItemsByIndex(for: batch)
            for localIndex in batch.cards.indices {
                let card = batch.cards[localIndex]
                let gradingItem = itemByIndex[localIndex + 1]
                let isCorrect = gradingItem?.isCorrect ?? false
                modelContext.insert(
                    VocabularyHandwritingAttempt(
                        cardID: card.id,
                        deckID: deck.id,
                        drawingData: drawingData(batch, localIndex),
                        isCorrect: isCorrect
                    )
                )
                try VocabularyMemoryScheduler.record(
                    card: card,
                    deck: deck,
                    direction: handwritingTestKind.reviewDirection,
                    rating: isCorrect ? .good : .again,
                    responseKind: handwritingTestKind.reviewResponseKind,
                    duration: duration,
                    modelContext: modelContext,
                    saveImmediately: false
                )
                sessionItems.append(
                    VocabularyStudySessionItemFactory.makeHandwritingTestAnswer(
                        card: card,
                        prompt: handwritingTestKind.prompt(
                            term: card.term,
                            definition: card.definition
                        ),
                        expectedAnswer: handwritingTestKind.referenceAnswer(
                            term: card.term,
                            englishDefinition: card.englishDefinition
                        ),
                        isCorrect: isCorrect,
                        recognizedText: gradingItem?.recognizedText ?? gradingItem?.comment ?? "",
                        comment: gradingItem?.comment ?? "",
                        keepsRecognizedTextForCorrectAnswer:
                            handwritingTestKind == .englishDefinition
                    )
                )
            }
        }

        guard let session = VocabularyStudySessionDraft(
            deckID: deck.id,
            kind: kind,
            startedAt: startedAt,
            endedAt: endedAt,
            items: sessionItems
        ).makeSession() else { return false }
        modelContext.insert(session)
        return true
    }
}
