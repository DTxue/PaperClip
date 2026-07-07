import SwiftUI

extension VocabularyStudyView {
    func prepareQuestion() {
        hasChecked = false
        isCorrect = false
        correctTiles = []
        wordBankTiles = []
        placedTileIDs = []
        startedAt = .now
        guard let card = current else { return }
        buildWordBank(for: card)
    }

    func buildWordBank(for card: VocabularyCard) {
        let cache = fetchDistractorCache(for: card)
        let correctTiles: [String]
        let distractorTiles: [String]
        if let cache {
            correctTiles = cache.correctTiles
            distractorTiles = cache.distractorTiles
        } else {
            correctTiles = [card.term]
            distractorTiles = VocabularyWordBankBuilder.sampleDistractorTerms(
                candidates: allCards,
                excluding: card,
                limit: maximumDistractorCount
            )
        }
        self.correctTiles = correctTiles
        wordBankTiles = VocabularyWordBankBuilder.build(
            correctTiles: correctTiles,
            distractorTiles: distractorTiles
        ).shuffled()
    }

    func fetchDistractorCache(for card: VocabularyCard) -> VocabularyDistractorCache? {
        do {
            return try modelContext.fetchVocabularyDistractorCache(
                deckID: deck.id,
                cardID: card.id,
                term: card.term
            )
        } catch {
            alert = AppAlert(title: "无法读取干扰项缓存", error: error)
            return nil
        }
    }
}
