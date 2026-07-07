import Foundation

struct VocabularyStudySessionsSnapshot {
    let sessions: [VocabularyStudySessionRowData]
    let averageAccuracy: Double
    let totalDuration: Double
    let limit: Int

    init(sessions: [VocabularyStudySessionRowData], limit: Int) {
        let summary = VocabularyStudySessionSummary(sessions: sessions)

        self.sessions = sessions
        self.averageAccuracy = summary.averageAccuracy
        self.totalDuration = summary.totalDuration
        self.limit = limit
    }

    var scopeTitle: String { VocabularyStudySessionSummary.scopeTitle(sessionCount: sessions.count, limit: limit) }
}

struct VocabularyStudySessionSummary {
    let totalDuration: Double
    let averageAccuracy: Double

    init(sessions: [VocabularyStudySessionRowData]) {
        self.init(durations: sessions.map(\.duration), metrics: sessions.map(\.metrics))
    }

    init(durations: [Double], metrics: [VocabularyStudySessionMetrics]) {
        totalDuration = durations.reduce(0, +)
        averageAccuracy = VocabularyStudySessionMetrics.aggregate(metrics).accuracy
    }

    static func scopeTitle(sessionCount: Int, limit: Int) -> String {
        guard limit > 0, sessionCount >= limit else { return "全部 \(sessionCount) 次" }
        return "最近 \(limit) 次"
    }
}

struct VocabularyStudySessionRowData: Identifiable, Hashable {
    let id: UUID
    let kind: String
    let endedAt: Date
    let duration: Double
    let totalCount: Int
    let correctCount: Int

    init(session: VocabularyStudySession) {
        id = session.id
        kind = session.kind
        endedAt = session.endedAt
        duration = session.duration
        totalCount = session.totalCount
        correctCount = session.correctCount
    }

    var errorRate: Double { metrics.errorRate }

    var metrics: VocabularyStudySessionMetrics { VocabularyStudySessionMetrics(totalCount: totalCount, correctCount: correctCount) }

    static var propertiesToFetch: [PartialKeyPath<VocabularyStudySession>] {
        [\.id, \.deckID, \.kind, \.endedAt, \.duration, \.totalCount, \.correctCount]
    }
}

struct VocabularyStudySessionDetailSnapshot {
    let incorrectItems: [VocabularyStudySessionItem]
    let correctItems: [VocabularyStudySessionItem]

    init(session: VocabularyStudySession) { self.init(items: session.items) }

    init(items: [VocabularyStudySessionItem]) {
        let groupedItems = VocabularyStudySessionItemGroups(items: items)
        incorrectItems = groupedItems.incorrectItems
        correctItems = groupedItems.correctItems
    }
}

struct VocabularyStudySessionItemGroups {
    let incorrectItems: [VocabularyStudySessionItem]
    let correctItems: [VocabularyStudySessionItem]

    init(items: [VocabularyStudySessionItem]) {
        let grouped = items.reduce(into: (incorrect: [VocabularyStudySessionItem](), correct: [VocabularyStudySessionItem]())) { result, item in
            if item.isCorrect {
                result.correct.append(item)
            } else {
                result.incorrect.append(item)
            }
        }
        incorrectItems = grouped.incorrect
        correctItems = grouped.correct
    }
}
