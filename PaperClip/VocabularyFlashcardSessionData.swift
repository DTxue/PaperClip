import SwiftUI

extension VocabularyFlashcardView {
    func orderedCards(for direction: VocabularyDirection) -> [VocabularyCard] {
        var stateByCardID: [UUID: VocabularyMemoryState] = [:]
        for state in states where state.direction == direction.rawValue {
            if stateByCardID[state.cardID] == nil {
                stateByCardID[state.cardID] = state
            }
        }

        let now = Date.now
        var due: [(card: VocabularyCard, dueDate: Date)] = []
        var fresh: [VocabularyCard] = []
        fresh.reserveCapacity(min(deck.dailyNewLimit, allCards.count))
        for card in allCards {
            if let state = stateByCardID[card.id] {
                if state.dueDate <= now {
                    due.append((card: card, dueDate: state.dueDate))
                }
            } else if fresh.count < deck.dailyNewLimit {
                fresh.append(card)
            }
        }

        due.sort { $0.dueDate < $1.dueDate }
        return due.map(\.card) + fresh
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
        startedAt = .now
        sessionStartedAt = .now
        sessionItems = []
        didRecordSession = false
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
