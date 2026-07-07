import Foundation
import SwiftData

extension ModelContext {
    func deleteVocabularyDeckCascade(deckID: UUID) throws {
        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyCard>(
            predicate: #Predicate<VocabularyCard> { card in card.deckID == deckID }
        ), fetching: VocabularyCard.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyMemoryState>(
            predicate: #Predicate<VocabularyMemoryState> { state in state.deckID == deckID }
        ), fetching: VocabularyMemoryState.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyReviewLog>(
            predicate: #Predicate<VocabularyReviewLog> { log in log.deckID == deckID }
        ), fetching: VocabularyReviewLog.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyStudySession>(
            predicate: #Predicate<VocabularyStudySession> { session in session.deckID == deckID }
        ), fetching: VocabularyStudySession.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyTestDraft>(
            predicate: #Predicate<VocabularyTestDraft> { draft in draft.deckID == deckID }
        ), fetching: VocabularyTestDraft.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyHandwritingAttempt>(
            predicate: #Predicate<VocabularyHandwritingAttempt> { attempt in attempt.deckID == deckID }
        ), fetching: VocabularyHandwritingAttempt.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyImportBatch>(
            predicate: #Predicate<VocabularyImportBatch> { batch in batch.deckID == deckID }
        ), fetching: VocabularyImportBatch.deletionPropertiesToFetch)

        try deleteVocabularyDistractorCaches(deckID: deckID)

        if let deck = try fetchVocabularyDeck(id: deckID) {
            delete(deck)
        }
    }

    func deleteVocabularyCardCascade(cardID: UUID) throws {
        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyMemoryState>(
            predicate: #Predicate<VocabularyMemoryState> { state in state.cardID == cardID }
        ), fetching: VocabularyMemoryState.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyReviewLog>(
            predicate: #Predicate<VocabularyReviewLog> { log in log.cardID == cardID }
        ), fetching: VocabularyReviewLog.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyHandwritingAttempt>(
            predicate: #Predicate<VocabularyHandwritingAttempt> { attempt in attempt.cardID == cardID }
        ), fetching: VocabularyHandwritingAttempt.deletionPropertiesToFetch)

        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyDistractorCache>(
            predicate: #Predicate<VocabularyDistractorCache> { cache in cache.cardID == cardID }
        ), fetching: VocabularyDistractorCache.deletionPropertiesToFetch)

        if let card = try fetchVocabularyCard(id: cardID) {
            delete(card)
        }
    }
}
