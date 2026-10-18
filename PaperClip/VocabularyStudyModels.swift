import Foundation
import SwiftData

extension PaperClipSchemaV1 {
private struct VocabularyStudySessionPayload: Codable {
    let items: [VocabularyStudySessionItem]
    let testSelectionDescription: String?
}

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
        items: [VocabularyStudySessionItem],
        testSelectionDescription: String? = nil
    ) {
        self.id = id
        self.deckID = deckID
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.totalCount = totalCount
        self.correctCount = correctCount
        self.itemsJSON = VocabularyJSONStorage.encode(
            VocabularyStudySessionPayload(
                items: items,
                testSelectionDescription: testSelectionDescription
            )
        )
    }

    convenience init(
        deckID: UUID,
        kind: String,
        startedAt: Date,
        endedAt: Date = .now,
        items: [VocabularyStudySessionItem],
        testSelectionDescription: String? = nil
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
            items: items,
            testSelectionDescription: testSelectionDescription
        )
    }

    var items: [VocabularyStudySessionItem] {
        if let payload = VocabularyJSONStorage.decodeOptional(
            VocabularyStudySessionPayload.self,
            from: itemsJSON
        ) {
            return payload.items
        }
        return VocabularyJSONStorage.decode(
            [VocabularyStudySessionItem].self,
            from: itemsJSON,
            fallback: []
        )
    }

    var testSelectionDescription: String? {
        VocabularyJSONStorage.decodeOptional(
            VocabularyStudySessionPayload.self,
            from: itemsJSON
        )?.testSelectionDescription
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
}

typealias VocabularyStudySession = PaperClipSchemaV1.VocabularyStudySession
