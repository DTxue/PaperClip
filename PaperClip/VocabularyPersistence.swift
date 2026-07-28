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

    func fetchVocabularyArticleCards(deckID: UUID) throws -> [VocabularyCard] {
        try fetchVocabularyCards(
            deckID: deckID,
            propertiesToFetch: VocabularyCard.articleGenerationPropertiesToFetch
        )
    }

    func fetchVocabularyGeneratedArticle(deckID: UUID) throws -> VocabularyGeneratedArticle? {
        let descriptor = FetchDescriptor<VocabularyGeneratedArticle>(
            predicate: #Predicate<VocabularyGeneratedArticle> { article in
                article.deckID == deckID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyGeneratedArticleSeries(
        deckID: UUID
    ) throws -> [VocabularyGeneratedArticle] {
        let descriptor = FetchDescriptor<VocabularyGeneratedArticle>(
            predicate: #Predicate<VocabularyGeneratedArticle> { article in
                article.deckID == deckID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let articles = try fetch(descriptor)
        guard let seriesID = articles.first?.sourceCardSnapshotHash else { return [] }
        return articles
            .filter { $0.sourceCardSnapshotHash == seriesID }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    func fetchVocabularyGeneratedArticleArchive(
        deckID: UUID
    ) throws -> [VocabularyGeneratedArticle] {
        let descriptor = FetchDescriptor<VocabularyGeneratedArticle>(
            predicate: #Predicate<VocabularyGeneratedArticle> { article in
                article.deckID == deckID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let articles = try fetch(descriptor)
        guard let currentSeriesID = articles.first?.sourceCardSnapshotHash else { return [] }
        return articles.filter { $0.sourceCardSnapshotHash != currentSeriesID }
    }

    @discardableResult
    func insertVocabularyGeneratedArticleSeries(
        deckID: UUID,
        drafts: [VocabularyArticleDraft]
    ) throws -> [VocabularyGeneratedArticle] {
        let now = Date()
        var articles: [VocabularyGeneratedArticle] = []
        articles.reserveCapacity(drafts.count)

        for (index, draft) in drafts.enumerated() {
            let coveredTermsData = try JSONEncoder().encode(draft.coveredTerms)
            let coveredTermsJSON = String(data: coveredTermsData, encoding: .utf8) ?? "[]"
            let timestamp = now.addingTimeInterval(Double(index) / 1_000)
            let article = VocabularyGeneratedArticle(
                deckID: deckID,
                title: draft.title,
                articleText: draft.articleText,
                coveredTermsJSON: coveredTermsJSON,
                sourceCardSnapshotHash: draft.sourceCardSnapshotHash,
                modelName: draft.modelName,
                promptVersion: draft.promptVersion,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            insert(article)
            articles.append(article)
        }

        return articles
    }

    @discardableResult
    func upsertVocabularyGeneratedArticle(
        deckID: UUID,
        draft: VocabularyArticleDraft
    ) throws -> VocabularyGeneratedArticle {
        let now = Date()
        let coveredTermsData = try JSONEncoder().encode(draft.coveredTerms)
        let coveredTermsJSON = String(data: coveredTermsData, encoding: .utf8) ?? "[]"

        if let article = try fetchVocabularyGeneratedArticle(deckID: deckID) {
            article.title = draft.title
            article.articleText = draft.articleText
            article.coveredTermsJSON = coveredTermsJSON
            article.sourceCardSnapshotHash = draft.sourceCardSnapshotHash
            article.modelName = draft.modelName
            article.promptVersion = draft.promptVersion
            article.updatedAt = now
            return article
        }

        let article = VocabularyGeneratedArticle(
            deckID: deckID,
            title: draft.title,
            articleText: draft.articleText,
            coveredTermsJSON: coveredTermsJSON,
            sourceCardSnapshotHash: draft.sourceCardSnapshotHash,
            modelName: draft.modelName,
            promptVersion: draft.promptVersion,
            createdAt: now,
            updatedAt: now
        )
        insert(article)
        return article
    }

    func fetchVocabularyArticleRecitationHistories(
        deckID: UUID,
        articleSnapshotHash: String
    ) throws -> [VocabularyArticleRecitationHistory] {
        try fetch(
            FetchDescriptor<VocabularyArticleRecitationHistory>(
                predicate: #Predicate<VocabularyArticleRecitationHistory> { history in
                    history.deckID == deckID && history.articleSnapshotHash == articleSnapshotHash
                },
                sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
            )
        )
    }

    func fetchVocabularyArticleRecitationHistories(
        articleID: UUID
    ) throws -> [VocabularyArticleRecitationHistory] {
        try fetch(
            FetchDescriptor<VocabularyArticleRecitationHistory>(
                predicate: #Predicate<VocabularyArticleRecitationHistory> { history in
                    history.articleID == articleID
                },
                sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
            )
        )
    }

    @discardableResult
    func recordVocabularyArticleRecitationHistory(
        article: VocabularyGeneratedArticle,
        duration: TimeInterval,
        sentenceCount: Int,
        wordCount: Int,
        stuckSentenceIndexes: [Int]
    ) -> VocabularyArticleRecitationHistory {
        let now = Date()
        let history = VocabularyArticleRecitationHistory(
            deckID: article.deckID,
            articleID: article.id,
            articleTitle: article.title,
            articleSnapshotHash: article.sourceCardSnapshotHash,
            completedAt: now,
            duration: duration,
            sentenceCount: sentenceCount,
            wordCount: wordCount,
            stuckSentenceIndexes: stuckSentenceIndexes,
            createdAt: now
        )
        insert(history)
        return history
    }
}

enum VocabularyArticleSeriesTransaction {
    @MainActor
    static func commit(
        modelContext: ModelContext,
        deckID: UUID,
        drafts: [VocabularyArticleDraft],
        saving: @MainActor (ModelContext) throws -> Void = { try $0.save() }
    ) throws -> [VocabularyGeneratedArticle] {
        let articles = try modelContext.insertVocabularyGeneratedArticleSeries(
            deckID: deckID,
            drafts: drafts
        )
        do {
            try saving(modelContext)
            return articles
        } catch {
            for article in articles {
                modelContext.delete(article)
            }
            throw error
        }
    }
}
