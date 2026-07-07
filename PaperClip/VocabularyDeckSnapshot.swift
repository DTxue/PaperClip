import Foundation

struct VocabularyDeckSnapshot {
    let visibleCards: [VocabularyCardRowData]
    let dueDirectionCount: Int
    let todayReviewCount: Int

    init(
        cards: [VocabularyCardRowData],
        states: [VocabularyMemoryState],
        todayReviewCount: Int,
        searchText: String,
        now: Date = .now
    ) {
        let stateIndex = VocabularyMemoryStateIndex(states)
        var deckCards: [VocabularyCardRowData] = []
        var due = 0
        deckCards.reserveCapacity(cards.count)

        for card in cards {
            if card.matchesSearch(searchText) {
                deckCards.append(card)
            }

            due += stateIndex.dueDirectionCount(for: card.id, now: now)
        }

        visibleCards = deckCards
        dueDirectionCount = due
        self.todayReviewCount = todayReviewCount
    }
}
