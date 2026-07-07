import Foundation
import SwiftData

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
}
