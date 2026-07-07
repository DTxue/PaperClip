import Foundation

struct VocabularyHomeCardCountInput {
    let id: UUID
    let deckID: UUID

    init(id: UUID, deckID: UUID) {
        self.id = id
        self.deckID = deckID
    }

    init(card: VocabularyCard) {
        self.init(id: card.id, deckID: card.deckID)
    }
}

struct VocabularyHomeFutureStateInput {
    let deckID: UUID?
    let cardID: UUID
    let direction: String

    init(deckID: UUID?, cardID: UUID, direction: String) {
        self.deckID = deckID
        self.cardID = cardID
        self.direction = direction
    }

    init(state: VocabularyMemoryState) {
        self.init(deckID: state.deckID, cardID: state.cardID, direction: state.direction)
    }
}

enum VocabularyHomeDueCount {
    static func count(totalCardCount: Int, futureDirectionKeyCount: Int) -> Int {
        max(0, totalCardCount * VocabularyDirection.allCases.count - futureDirectionKeyCount)
    }
}
