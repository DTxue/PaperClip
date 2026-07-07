import Foundation
import SwiftData

enum VocabularyMaintenance {
    @MainActor
    static func backfillMemoryStateDeckIDs(in container: ModelContainer) {
        let context = container.mainContext
        do {
            let states = try context.fetchVocabularyMemoryStatesMissingDeckID()
            guard !states.isEmpty else { return }

            let cards = try context.fetchVocabularyCards(
                propertiesToFetch: VocabularyCard.homeCountPropertiesToFetch
            )
            var deckIDByCardID: [UUID: UUID] = [:]
            deckIDByCardID.reserveCapacity(cards.count)
            for card in cards {
                deckIDByCardID[card.id] = card.deckID
            }
            for state in states {
                state.deckID = deckIDByCardID[state.cardID]
            }
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
        }
    }
}

extension ModelContext {
    @discardableResult
    func deleteFetchedVocabularyRows<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        fetching propertiesToFetch: [PartialKeyPath<Model>]
    ) throws -> Int {
        var descriptor = descriptor
        descriptor.propertiesToFetch = propertiesToFetch
        return try deleteFetched(descriptor)
    }
}
