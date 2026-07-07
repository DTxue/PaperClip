import Foundation

struct VocabularyGeneratedDistractorCache: Equatable {
    let cardID: UUID
    let deckID: UUID
    let correctTiles: [String]
    let distractorTiles: [String]
    let cardTermSnapshot: String
}
