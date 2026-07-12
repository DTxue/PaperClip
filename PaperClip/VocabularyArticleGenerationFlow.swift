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
        expectedSeriesID: String?,
        modelContext: ModelContext,
        isCurrentRequest: () -> Bool,
        progress: (Int, Int) -> Void
    ) async throws -> VocabularyArticleGenerationOutput {
        try Task.checkCancellation()

        let cards = try modelContext.fetchVocabularyArticleCards(deckID: deckID)
        guard !cards.isEmpty else { throw VocabularyArticleGenerationFlowError.noCards }

        let inputs = cards.map { VocabularyArticleCardInput(card: $0) }
        let cardFingerprint = VocabularyArticleSourceFingerprint.make(cards: inputs)
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
        let currentCards = try modelContext.fetchVocabularyArticleCards(deckID: deckID)
        let currentCardFingerprint = VocabularyArticleSourceFingerprint.make(
            cards: currentCards.map { VocabularyArticleCardInput(card: $0) }
        )
        let existingSeries = try modelContext.fetchVocabularyGeneratedArticleSeries(deckID: deckID)
        let currentSeriesID = existingSeries.first?.sourceCardSnapshotHash

        guard currentCardFingerprint == cardFingerprint else {
            throw VocabularyArticleGenerationFlowError.sourceCardsChanged
        }
        guard currentSeriesID == expectedSeriesID else {
            throw VocabularyArticleGenerationFlowError.currentSeriesChanged
        }
        guard VocabularyArticleGenerationCommitPolicy.canCommit(
            expectedSeriesID: expectedSeriesID,
            currentSeriesID: currentSeriesID,
            expectedCardFingerprint: cardFingerprint,
            currentCardFingerprint: currentCardFingerprint,
            replacementConfirmed: replacementConfirmed,
            isCancelled: Task.isCancelled,
            isCurrentRequest: isCurrentRequest()
        ) else {
            if Task.isCancelled { throw CancellationError() }
            if !isCurrentRequest() { throw VocabularyArticleGenerationFlowError.staleRequest }
            throw VocabularyArticleGenerationFlowError.replacementNotConfirmed
        }
        try Task.checkCancellation()

        let articles = try VocabularyArticleSeriesTransaction.commit(
            modelContext: modelContext,
            deckID: deckID,
            drafts: drafts
        )
        let archivedArticles = try modelContext.fetchVocabularyGeneratedArticleArchive(
            deckID: deckID
        )
        return VocabularyArticleGenerationOutput(
            cards: currentCards,
            articles: articles,
            archivedArticles: archivedArticles
        )
    }
}

enum VocabularyArticleGenerationFlowError: LocalizedError {
    case noCards
    case replacementNotConfirmed
    case sourceCardsChanged
    case currentSeriesChanged
    case staleRequest

    var errorDescription: String? {
        switch self {
        case .noCards:
            "当前词集没有可用于生成故事的词条。"
        case .replacementNotConfirmed:
            "当前词生文已发生变化，本次生成没有覆盖它。请重新确认后再试。"
        case .sourceCardsChanged:
            "生成期间词集内容发生了变化，本次结果没有保存。请重新生成。"
        case .currentSeriesChanged:
            "生成期间当前故事系列发生了变化，本次结果没有覆盖它。请重新确认后再试。"
        case .staleRequest:
            "本次生成任务已失效，结果没有保存。"
        }
    }
}
