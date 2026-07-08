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

@MainActor
func generateVocabularyEnglishDefinitions(
    for cards: [VocabularyCard],
    isCurrent: () -> Bool,
    onProgress: (Int) -> Void
) async throws -> [VocabularyGeneratedEnglishDefinition] {
    let batchSize = 30
    var generatedDefinitions: [VocabularyGeneratedEnglishDefinition] = []
    generatedDefinitions.reserveCapacity(cards.count)

    var startIndex = cards.startIndex
    while startIndex < cards.endIndex {
        let endIndex = cards.index(startIndex, offsetBy: batchSize, limitedBy: cards.endIndex) ?? cards.endIndex
        let batch = cards[startIndex..<endIndex].map { card in
            VocabularyEnglishDefinitionInput(
                cardID: card.id,
                term: card.term,
                definition: card.definition,
                partOfSpeech: card.partOfSpeech,
                example: card.example
            )
        }

        let result = try await AIService.generateEnglishDefinitions(cards: batch)
        try Task.checkCancellation()
        guard isCurrent() else { throw CancellationError() }
        generatedDefinitions.append(contentsOf: result)
        onProgress(result.count)
        startIndex = endIndex
    }

    return generatedDefinitions
}
