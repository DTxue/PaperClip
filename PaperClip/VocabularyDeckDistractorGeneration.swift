import Foundation

@MainActor
func generateVocabularyDistractorCaches(
    for cards: [VocabularyCard],
    deckID: UUID,
    config: DistractorConfig,
    isCurrent: () -> Bool,
    onProgress: () -> Void
) async throws -> [VocabularyGeneratedDistractorCache] {
    var generatedCaches: [VocabularyGeneratedDistractorCache] = []
    generatedCaches.reserveCapacity(cards.count)

    for card in cards {
        let result = try await AIService.generateDistractors(
            term: card.term,
            definition: card.definition,
            partOfSpeech: card.partOfSpeech,
            example: card.example,
            config: config
        )
        try Task.checkCancellation()
        guard isCurrent() else { throw CancellationError() }
        generatedCaches.append(VocabularyGeneratedDistractorCache(
            cardID: card.id,
            deckID: deckID,
            correctTiles: result.correctTiles,
            distractorTiles: result.distractorTiles,
            cardTermSnapshot: card.term
        ))
        onProgress()
    }

    return generatedCaches
}
