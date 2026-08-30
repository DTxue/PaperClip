import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class VocabularyDistractorCache {
    static var freshnessPropertiesToFetch: [PartialKeyPath<VocabularyDistractorCache>] {
        [\.cardID, \.cardTermSnapshot]
    }

    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyDistractorCache>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var deckID: UUID
    var correctTilesJSON: String
    var distractorTilesJSON: String
    var cardTermSnapshot: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cardID: UUID,
        deckID: UUID,
        correctTiles: [String],
        distractorTiles: [String],
        cardTermSnapshot: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.cardID = cardID
        self.deckID = deckID
        self.correctTilesJSON = VocabularyJSONStorage.encode(correctTiles)
        self.distractorTilesJSON = VocabularyJSONStorage.encode(distractorTiles)
        self.cardTermSnapshot = cardTermSnapshot
        self.createdAt = createdAt
    }

    var correctTiles: [String] {
        VocabularyJSONStorage.decode([String].self, from: correctTilesJSON, fallback: [])
    }

    var distractorTiles: [String] {
        VocabularyJSONStorage.decode([String].self, from: distractorTilesJSON, fallback: [])
    }
}
}

typealias VocabularyDistractorCache = PaperClipSchemaV1.VocabularyDistractorCache
