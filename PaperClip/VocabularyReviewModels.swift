import Foundation
import SwiftData

@Model
final class VocabularyReviewLog {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyReviewLog>] {
        [\.id]
    }

    static var masteryPropertiesToFetch: [PartialKeyPath<VocabularyReviewLog>] {
        [\.cardID, \.direction, \.rating, \.responseKind, \.reviewedAt]
    }

    static var testSelectionPropertiesToFetch: [PartialKeyPath<VocabularyReviewLog>] {
        [\.cardID, \.rating, \.reviewedAt]
    }

    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var deckID: UUID
    var direction: String
    var rating: Int
    var responseKind: String
    var duration: Double
    var reviewedAt: Date
    var previousStability: Double
    var resultingStability: Double
    var previousDifficulty: Double = 0
    var resultingDifficulty: Double = 0
    var retrievability: Double = 0
    var elapsedDays: Double = 0
    var scheduledDays: Double = 0
    var reviewState: String = VocabularyMemoryStage.new.rawValue
    var algorithmVersion: Int = 0

    init(
        id: UUID = UUID(),
        cardID: UUID,
        deckID: UUID,
        direction: VocabularyDirection,
        rating: VocabularyReviewRating,
        responseKind: String,
        duration: Double,
        reviewedAt: Date = .now,
        previousStability: Double,
        resultingStability: Double,
        previousDifficulty: Double = 0,
        resultingDifficulty: Double = 0,
        retrievability: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        reviewState: String = VocabularyMemoryStage.new.rawValue,
        algorithmVersion: Int = 6
    ) {
        self.id = id
        self.cardID = cardID
        self.deckID = deckID
        self.direction = direction.rawValue
        self.rating = rating.rawValue
        self.responseKind = responseKind
        self.duration = duration
        self.reviewedAt = reviewedAt
        self.previousStability = previousStability
        self.resultingStability = resultingStability
        self.previousDifficulty = previousDifficulty
        self.resultingDifficulty = resultingDifficulty
        self.retrievability = retrievability
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reviewState = reviewState
        self.algorithmVersion = algorithmVersion
    }
}
