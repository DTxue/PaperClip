import Foundation
import SwiftData

@Model
final class VocabularyStudySession {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyStudySession>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var kind: String
    var startedAt: Date
    var endedAt: Date
    var duration: Double
    var totalCount: Int
    var correctCount: Int
    var itemsJSON: String

    init(
        id: UUID = UUID(),
        deckID: UUID,
        kind: String,
        startedAt: Date,
        endedAt: Date = .now,
        duration: Double,
        totalCount: Int,
        correctCount: Int,
        items: [VocabularyStudySessionItem]
    ) {
        self.id = id
        self.deckID = deckID
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.totalCount = totalCount
        self.correctCount = correctCount
        self.itemsJSON = VocabularyJSONStorage.encode(items)
    }

    convenience init(
        deckID: UUID,
        kind: String,
        startedAt: Date,
        endedAt: Date = .now,
        items: [VocabularyStudySessionItem]
    ) {
        let metrics = VocabularyStudySessionMetrics(correctness: items.map(\.isCorrect))
        self.init(
            deckID: deckID,
            kind: kind,
            startedAt: startedAt,
            endedAt: endedAt,
            duration: endedAt.timeIntervalSince(startedAt),
            totalCount: metrics.totalCount,
            correctCount: metrics.correctCount,
            items: items
        )
    }

    var items: [VocabularyStudySessionItem] {
        VocabularyJSONStorage.decode([VocabularyStudySessionItem].self, from: itemsJSON, fallback: [])
    }

    var accuracy: Double {
        metrics.accuracy
    }

    var errorRate: Double {
        metrics.errorRate
    }

    var metrics: VocabularyStudySessionMetrics {
        VocabularyStudySessionMetrics(totalCount: totalCount, correctCount: correctCount)
    }
}
