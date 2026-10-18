import Foundation
import SwiftData

enum VocabularyDeckKind: String, CaseIterable, Identifiable, Sendable {
    case word
    case sentence
    case dictationChinese
    case dictationOther

    var id: String { rawValue }

    var usesWordSpecificFeatures: Bool {
        self == .word
    }

    var homeBoard: VocabularyHomeBoard {
        switch self {
        case .word, .sentence: .english
        case .dictationChinese: .chinese
        case .dictationOther: .other
        }
    }

    var usesSentenceTiles: Bool {
        !usesWordSpecificFeatures
    }

    /// Historical decks store "英语" here and therefore remain word decks.
    /// The sentence marker keeps the existing V1 store compatible without a schema migration.
    fileprivate init(sourceLanguage: String) {
        switch sourceLanguage {
        case Self.sentenceSourceLanguage: self = .sentence
        case Self.dictationEnglishSourceLanguage: self = .word
        case Self.dictationChineseSourceLanguage: self = .dictationChinese
        case Self.dictationOtherSourceLanguage: self = .dictationOther
        default: self = .word
        }
    }

    fileprivate var sourceLanguageStorageValue: String {
        switch self {
        case .word: "英语"
        case .sentence: Self.sentenceSourceLanguage
        case .dictationChinese: Self.dictationChineseSourceLanguage
        case .dictationOther: Self.dictationOtherSourceLanguage
        }
    }

    private static let sentenceSourceLanguage = "英语（句集）"
    private static let dictationEnglishSourceLanguage = "默写（英语）"
    private static let dictationChineseSourceLanguage = "默写（语文）"
    private static let dictationOtherSourceLanguage = "默写（其他）"
}

enum VocabularyHomeBoard: String, CaseIterable, Identifiable {
    case english
    case chinese
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "英语"
        case .chinese: "语文"
        case .other: "其他"
        }
    }

    var kinds: [VocabularyDeckKind] {
        switch self {
        case .english: [.word, .sentence]
        case .chinese: [.dictationChinese]
        case .other: [.dictationOther]
        }
    }

    var systemImage: String {
        switch self {
        case .english: "character.book.closed.fill"
        case .chinese: "character.book.closed"
        case .other: "text.quote"
        }
    }

    var summary: String {
        switch self {
        case .english: "英语词集和句集"
        case .chinese: "语文默写内容"
        case .other: "其他默写内容"
        }
    }
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
