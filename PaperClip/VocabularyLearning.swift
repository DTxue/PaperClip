import Foundation
import SwiftData

extension VocabularyMemoryScheduler {
    @MainActor
    static func record(
        card: VocabularyCard,
        deck: VocabularyDeck,
        direction: VocabularyDirection,
        rating: VocabularyReviewRating,
        responseKind: String,
        duration: TimeInterval,
        modelContext: ModelContext,
        saveImmediately: Bool = true,
        now: Date = .now
    ) throws {
        let state = try modelContext.fetchVocabularyMemoryState(
            cardID: card.id,
            direction: direction
        ) ?? {
            let created = VocabularyMemoryState(deckID: deck.id, cardID: card.id, direction: direction)
            modelContext.insert(created)
            return created
        }()
        if state.deckID != deck.id {
            state.deckID = deck.id
        }

        let elapsedDays = VocabularyMemoryRetrievability.elapsedDays(
            from: state.lastReviewDate,
            to: now
        )
        let previous = state.reviewSnapshot(elapsedDays: elapsedDays)
        let result = review(
            state: state,
            rating: rating,
            desiredRetention: deck.desiredRetention,
            parameters: VocabularyMemoryRetrievability.parameters(for: deck),
            fuzzFactor: VocabularyReviewFuzzFactor.factor(
                cardID: card.id,
                direction: direction,
                reviewCount: state.reviewCount
            ),
            now: now
        )
        state.apply(result, reviewedAt: now)

        modelContext.insert(
            VocabularyReviewLog(
                card: card,
                deck: deck,
                direction: direction,
                rating: rating,
                responseKind: responseKind,
                duration: duration,
                previous: previous,
                result: result
            )
        )
        if saveImmediately {
            try modelContext.saveOrRollbackIfNeeded()
        }
    }
}
