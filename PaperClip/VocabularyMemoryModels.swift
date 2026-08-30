import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class VocabularyMemoryState {
    @Attribute(.unique) var id: UUID
    var deckID: UUID?
    var cardID: UUID
    var direction: String
    var stage: String
    var dueDate: Date
    var lastReviewDate: Date?
    var stability: Double
    var difficulty: Double
    var retrievability: Double
    var scheduledDays: Double = 0
    var learningStep: Int = 0
    var algorithmVersion: Int = 0
    var reviewCount: Int
    var lapseCount: Int

    init(
        id: UUID = UUID(),
        deckID: UUID? = nil,
        cardID: UUID,
        direction: VocabularyDirection,
        stage: VocabularyMemoryStage = .new,
        dueDate: Date = .now,
        lastReviewDate: Date? = nil,
        stability: Double = 0,
        difficulty: Double = 0,
        retrievability: Double = 0,
        scheduledDays: Double = 0,
        learningStep: Int = 0,
        algorithmVersion: Int = 6,
        reviewCount: Int = 0,
        lapseCount: Int = 0
    ) {
        self.id = id
        self.deckID = deckID
        self.cardID = cardID
        self.direction = direction.rawValue
        self.stage = stage.rawValue
        self.dueDate = dueDate
        self.lastReviewDate = lastReviewDate
        self.stability = stability
        self.difficulty = difficulty
        self.retrievability = retrievability
        self.scheduledDays = scheduledDays
        self.learningStep = learningStep
        self.algorithmVersion = algorithmVersion
        self.reviewCount = reviewCount
        self.lapseCount = lapseCount
    }
}
}

typealias VocabularyMemoryState = PaperClipSchemaV1.VocabularyMemoryState

extension VocabularyMemoryState {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] {
        [\.id]
    }

    static var futureDuePropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] {
        [\.deckID, \.cardID, \.direction]
    }

    static var dueLookupPropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] {
        [\.cardID, \.direction, \.dueDate]
    }

    static var sessionPropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] {
        [
            \.cardID,
            \.direction,
            \.dueDate,
            \.stage,
            \.stability,
            \.lastReviewDate,
            \.lapseCount,
            \.difficulty
        ]
    }

    static var masteryPropertiesToFetch: [PartialKeyPath<VocabularyMemoryState>] {
        [
            \.cardID,
            \.direction,
            \.dueDate,
            \.stage,
            \.stability,
            \.lastReviewDate,
            \.difficulty,
            \.reviewCount,
            \.lapseCount
        ]
    }
}
