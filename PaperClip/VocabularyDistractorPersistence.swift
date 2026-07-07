import Foundation
import SwiftData

extension ModelContext {
    func fetchVocabularyDistractorCaches(
        deckID: UUID,
        propertiesToFetch: [PartialKeyPath<VocabularyDistractorCache>] = []
    ) throws -> [VocabularyDistractorCache] {
        var descriptor = FetchDescriptor<VocabularyDistractorCache>(
            predicate: #Predicate<VocabularyDistractorCache> { cache in
                cache.deckID == deckID
            }
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchVocabularyDistractorCache(
        deckID: UUID,
        cardID: UUID,
        term: String
    ) throws -> VocabularyDistractorCache? {
        let descriptor = FetchDescriptor<VocabularyDistractorCache>(
            predicate: #Predicate<VocabularyDistractorCache> { cache in
                cache.deckID == deckID
                    && cache.cardID == cardID
                    && cache.cardTermSnapshot == term
            }
        )
        return try fetchFirst(descriptor)
    }

    @discardableResult
    func deleteVocabularyDistractorCaches(deckID: UUID) throws -> Int {
        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyDistractorCache>(
            predicate: #Predicate<VocabularyDistractorCache> { cache in
                cache.deckID == deckID
            }
        ), fetching: VocabularyDistractorCache.deletionPropertiesToFetch)
    }

    func replaceVocabularyDistractorCaches(
        deckID: UUID,
        with generatedCaches: [VocabularyGeneratedDistractorCache]
    ) throws {
        try deleteVocabularyDistractorCaches(deckID: deckID)
        for cache in generatedCaches where cache.deckID == deckID {
            insert(VocabularyDistractorCache(
                cardID: cache.cardID,
                deckID: cache.deckID,
                correctTiles: cache.correctTiles,
                distractorTiles: cache.distractorTiles,
                cardTermSnapshot: cache.cardTermSnapshot
            ))
        }
        try saveOrRollbackIfNeeded()
    }
}
