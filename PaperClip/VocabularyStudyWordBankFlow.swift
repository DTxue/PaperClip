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
        if deck.kind.usesSentenceTiles {
            correctTiles = VocabularyWordBankBuilder.sentenceTiles(card.term)
            let distractors = deck.kind == .sentence ? sentenceDistractorTiles(excluding: card) : []
            wordBankTiles = VocabularyWordBankBuilder.build(
                correctTiles: correctTiles,
                distractorTiles: distractors,
                maximumDistractorCount: deck.kind == .sentence ? totalCount : 0
            ).shuffled()
            return
        }

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

    private func sentenceDistractorTiles(excluding card: VocabularyCard) -> [String] {
        let correct = Set(VocabularyWordBankBuilder.sentenceTiles(card.term))
        var seen = correct
        let candidates: [String] = allCards
            .filter { $0.id != card.id }
            .flatMap { VocabularyWordBankBuilder.sentenceTiles($0.term) }
            .filter { tile in
                !tile.isEmpty && seen.insert(tile).inserted
            }
        return Array(candidates.shuffled().prefix(max(0, totalCount)))
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
