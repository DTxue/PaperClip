import Foundation
import SwiftData

@Model
final class VocabularyHandwritingAttempt {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyHandwritingAttempt>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var deckID: UUID
    @Attribute(.externalStorage) var drawingData: Data
    var isCorrect: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cardID: UUID,
        deckID: UUID,
        drawingData: Data,
        isCorrect: Bool,
        createdAt: Date = .now
    ) {
        self.id = id
        self.cardID = cardID
        self.deckID = deckID
        self.drawingData = drawingData
        self.isCorrect = isCorrect
        self.createdAt = createdAt
    }
}
