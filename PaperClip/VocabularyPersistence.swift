import Foundation
import SwiftData

extension ModelContext {
    func fetchVocabularyDeck(id: UUID) throws -> VocabularyDeck? {
        let descriptor = FetchDescriptor<VocabularyDeck>(
            predicate: #Predicate<VocabularyDeck> { deck in
                deck.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyDecks(
        propertiesToFetch: [PartialKeyPath<VocabularyDeck>] = []
    ) throws -> [VocabularyDeck] {
        try fetchConfigured(
            FetchDescriptor<VocabularyDeck>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

    func fetchVocabularyCard(id: UUID) throws -> VocabularyCard? {
        let descriptor = FetchDescriptor<VocabularyCard>(
            predicate: #Predicate<VocabularyCard> { card in
                card.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyCards(
        propertiesToFetch: [PartialKeyPath<VocabularyCard>] = []
    ) throws -> [VocabularyCard] {
        try fetchConfigured(
            FetchDescriptor<VocabularyCard>(),
            propertiesToFetch: propertiesToFetch
        )
    }

    func fetchVocabularyCards(
        deckID: UUID,
        propertiesToFetch: [PartialKeyPath<VocabularyCard>] = []
    ) throws -> [VocabularyCard] {
        try fetchConfigured(
            FetchDescriptor<VocabularyCard>(
                predicate: #Predicate<VocabularyCard> { card in
                    card.deckID == deckID
                },
                sortBy: [SortDescriptor(\.createdAt)]
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

    func fetchVocabularySessionCards(deckID: UUID) throws -> [VocabularyCard] {
        try fetchVocabularyCards(
            deckID: deckID,
            propertiesToFetch: VocabularyCard.sessionPropertiesToFetch
        )
    }
}
