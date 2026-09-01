import Foundation
import SwiftData

enum VocabularyDeckKind: String, CaseIterable, Identifiable, Sendable {
    case word
    case sentence

    var id: String { rawValue }

    var usesWordSpecificFeatures: Bool {
        self == .word
    }

    /// Historical decks store "英语" here and therefore remain word decks.
    /// The sentence marker keeps the existing V1 store compatible without a schema migration.
    fileprivate init(sourceLanguage: String) {
        self = sourceLanguage == Self.sentenceSourceLanguage ? .sentence : .word
    }

    fileprivate var sourceLanguageStorageValue: String {
        switch self {
        case .word: "英语"
        case .sentence: Self.sentenceSourceLanguage
        }
    }

    private static let sentenceSourceLanguage = "英语（句集）"
}

extension VocabularyDeck {
    var kind: VocabularyDeckKind {
        get { VocabularyDeckKind(sourceLanguage: sourceLanguage) }
        set { sourceLanguage = newValue.sourceLanguageStorageValue }
    }
}

extension ModelContext {
    func fetchVocabularyFolder(id: UUID) throws -> VocabularyFolder? {
        let descriptor = FetchDescriptor<VocabularyFolder>(
            predicate: #Predicate<VocabularyFolder> { folder in
                folder.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyFolders(
        propertiesToFetch: [PartialKeyPath<VocabularyFolder>] = []
    ) throws -> [VocabularyFolder] {
        try fetchConfigured(
            FetchDescriptor<VocabularyFolder>(
                sortBy: [
                    SortDescriptor(\.updatedAt, order: .reverse),
                    SortDescriptor(\.title)
                ]
            ),
            propertiesToFetch: propertiesToFetch
        )
    }

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
