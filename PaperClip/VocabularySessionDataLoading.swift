import Foundation
import SwiftData

struct VocabularySessionData {
    let cards: [VocabularyCard]
    let states: [VocabularyMemoryState]
}

extension ModelContext {
    func fetchVocabularySessionData(
        deckID: UUID,
        direction: VocabularyDirection? = nil,
        statePropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] = []
    ) throws -> VocabularySessionData {
        let cards = try fetchVocabularySessionCards(deckID: deckID)
        let states: [VocabularyMemoryState]
        if let direction {
            states = try fetchVocabularyMemoryStates(
                deckID: deckID,
                direction: direction,
                propertiesToFetch: statePropertiesToFetch
            )
        } else {
            states = try fetchVocabularyMemoryStates(
                deckID: deckID,
                propertiesToFetch: statePropertiesToFetch
            )
        }
        return VocabularySessionData(cards: cards, states: states)
    }
}
