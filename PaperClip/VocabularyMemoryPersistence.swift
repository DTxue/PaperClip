import Foundation
import SwiftData

extension ModelContext {
    func fetchVocabularyMemoryState(
        cardID: UUID,
        direction: VocabularyDirection
    ) throws -> VocabularyMemoryState? {
        let directionValue = direction.rawValue
        let descriptor = FetchDescriptor<VocabularyMemoryState>(
            predicate: #Predicate<VocabularyMemoryState> { state in
                state.cardID == cardID && state.direction == directionValue
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyMemoryStatesMissingDeckID() throws -> [VocabularyMemoryState] {
        try fetchConfigured(
            FetchDescriptor<VocabularyMemoryState>(
                predicate: #Predicate<VocabularyMemoryState> { state in
                    state.deckID == nil
                }
            ),
            propertiesToFetch: [\.cardID, \.deckID]
        )
    }

    func fetchVocabularyMemoryStates(
        deckID: UUID,
        propertiesToFetch: [PartialKeyPath<VocabularyMemoryState>]
    ) throws -> [VocabularyMemoryState] {
        try fetchConfigured(
            FetchDescriptor<VocabularyMemoryState>(
                predicate: #Predicate<VocabularyMemoryState> { state in
                    state.deckID == deckID
                }
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

    func fetchVocabularyMemoryStates(
        deckID: UUID,
        direction: VocabularyDirection,
        propertiesToFetch: [PartialKeyPath<VocabularyMemoryState>]
    ) throws -> [VocabularyMemoryState] {
        let directionValue = direction.rawValue
        return try fetchConfigured(
            FetchDescriptor<VocabularyMemoryState>(
                predicate: #Predicate<VocabularyMemoryState> { state in
                    state.deckID == deckID && state.direction == directionValue
                }
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

    func fetchFutureVocabularyMemoryStates(
        after date: Date,
        propertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] = []
    ) throws -> [VocabularyMemoryState] {
        try fetchConfigured(
            FetchDescriptor<VocabularyMemoryState>(
                predicate: #Predicate<VocabularyMemoryState> { state in
                    state.deckID != nil && state.dueDate > date
                }
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

    @discardableResult
    func resetVocabularyMastery(deckID: UUID) throws -> (memoryStateCount: Int, reviewLogCount: Int) {
        let memoryStateCount = try deleteFetchedVocabularyRows(
            FetchDescriptor<VocabularyMemoryState>(
                predicate: #Predicate<VocabularyMemoryState> { state in
                    state.deckID == deckID
                }
            ),
            fetching: VocabularyMemoryState.deletionPropertiesToFetch
        )
        let reviewLogCount = try deleteFetchedVocabularyRows(
            FetchDescriptor<VocabularyReviewLog>(
                predicate: #Predicate<VocabularyReviewLog> { log in
                    log.deckID == deckID
                }
            ),
            fetching: VocabularyReviewLog.deletionPropertiesToFetch
        )
        return (memoryStateCount, reviewLogCount)
    }
}
