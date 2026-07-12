import Foundation
import SwiftData

struct VocabularyArticleGenerationOutput {
    let cards: [VocabularyCard]
    let articles: [VocabularyGeneratedArticle]
    let archivedArticles: [VocabularyGeneratedArticle]
}

enum VocabularyArticleGenerationFlow {
    @MainActor
    static func generate(
        deckID: UUID,
        configuration: VocabularyArticleGenerationConfiguration,
        replacementConfirmed: Bool,
        modelContext: ModelContext,
        progress: (Int, Int) -> Void
    ) async throws -> VocabularyArticleGenerationOutput {
        try Task.checkCancellation()

        let cards = try modelContext.fetchVocabularyArticleCards(deckID: deckID)
        guard !cards.isEmpty else { throw VocabularyArticleGenerationFlowError.noCards }

        let inputs = cards.map { VocabularyArticleCardInput(card: $0) }
        let plan = VocabularyArticleGenerationPlan.make(
            cards: inputs,
            configuration: configuration
        )
        let seriesID = [
            "v2",
            VocabularyArticleSourceFingerprint.make(cards: inputs),
            UUID().uuidString.lowercased()
        ].joined(separator: ":")
        var drafts: [VocabularyArticleDraft] = []
        drafts.reserveCapacity(plan.stories.count)

        for story in plan.stories {
            try Task.checkCancellation()
            progress(story.index + 1, story.totalCount)
            drafts.append(try await AIService.generateVocabularyArticle(
                story: story,
                seriesID: seriesID
            ))
        }

        try Task.checkCancellation()
        let existingSeries = try modelContext.fetchVocabularyGeneratedArticleSeries(deckID: deckID)
        guard existingSeries.isEmpty || replacementConfirmed else {
            throw VocabularyArticleGenerationFlowError.replacementNotConfirmed
        }

        let articles = try VocabularyArticleSeriesTransaction.commit(
            modelContext: modelContext,
            deckID: deckID,
            drafts: drafts
        )
        let archivedArticles = try modelContext.fetchVocabularyGeneratedArticleArchive(
            deckID: deckID
        )
        return VocabularyArticleGenerationOutput(
            cards: cards,
            articles: articles,
            archivedArticles: archivedArticles
        )
    }
}

enum VocabularyArticleGenerationFlowError: LocalizedError {
    case noCards
    case replacementNotConfirmed

    var errorDescription: String? {
        switch self {
        case .noCards:
            "当前词集没有可用于生成故事的词条。"
        case .replacementNotConfirmed:
            "当前词生文已发生变化，本次生成没有覆盖它。请重新确认后再试。"
        }
    }
}
