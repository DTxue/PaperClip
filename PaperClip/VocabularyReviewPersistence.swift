import Foundation
import SwiftData

extension ModelContext {
    func fetchVocabularyReviewLogs(
        deckID: UUID,
        direction: VocabularyDirection? = nil,
        limit: Int,
        propertiesToFetch: [PartialKeyPath<VocabularyReviewLog>] = []
    ) throws -> [VocabularyReviewLog] {
        var descriptor: FetchDescriptor<VocabularyReviewLog>
        if let direction {
            let directionValue = direction.rawValue
            descriptor = FetchDescriptor<VocabularyReviewLog>(
                predicate: #Predicate<VocabularyReviewLog> { log in
                    log.deckID == deckID && log.direction == directionValue
                },
                sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<VocabularyReviewLog>(
                predicate: #Predicate<VocabularyReviewLog> { log in
                    log.deckID == deckID
                },
                sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)]
            )
        }
        descriptor.fetchLimit = limit
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchVocabularyReviewCount(
        deckID: UUID,
        since startDate: Date
    ) throws -> Int {
        try fetchCount(FetchDescriptor<VocabularyReviewLog>(
            predicate: #Predicate<VocabularyReviewLog> { log in
                log.deckID == deckID && log.reviewedAt >= startDate
            }
        ))
    }
}
