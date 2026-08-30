import SwiftUI

extension VocabularyFlashcardView {
    func orderedCards(for direction: VocabularyDirection) -> [VocabularyCard] {
        VocabularyFlashcardQueue.orderedCards(
            cards: allCards,
            states: states,
            direction: direction
        )
    }

    func resetSession() {
        fetchSessionData()
        queue = orderedCards(for: direction)
        nextRound = []
        index = 0
        initialCount = queue.count
        round = 1
        roundKnownCount = 0
        roundLearningCount = 0
        completedCardIDs = []
        isRevealed = false
        swipeOffset = .zero
        cardEntryOffset = 0
        cardEntryOpacity = 1
        isAnimatingSwipe = false
        roundFinished = false
        sessionFinished = false
    }

    func fetchSessionData() {
        let deckID = deck.id
        do {
            let data = try modelContext.fetchVocabularySessionData(
                deckID: deckID,
                statePropertiesToFetch: VocabularyMemoryState.dueLookupPropertiesToFetch
            )
            allCards = data.cards
            states = data.states
        } catch {
            allCards = []
            states = []
            alert = AppAlert(title: "无法读取闪卡队列", error: error)
        }
    }
}
