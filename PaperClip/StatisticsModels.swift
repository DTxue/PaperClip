import Foundation
import SwiftData

struct StatisticsSnapshot {
    static var vocabularySessionPropertiesToFetch: [PartialKeyPath<VocabularyStudySession>] {
        [\.deckID, \.kind, \.endedAt, \.duration, \.totalCount, \.correctCount]
    }

    static var vocabularyDeckPropertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.title]
    }

    let vocabularySummary: StatisticsVocabularySummary

    static let empty = StatisticsSnapshot(
        vocabularySummary: .empty
    )

    static func load(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        now: Date = .now
    ) throws -> StatisticsSnapshot {
        StatisticsSnapshot(
            vocabularySummary: try StatisticsVocabularySummary.make(
                modelContext: modelContext,
                calendar: calendar,
                now: now,
                sessionPropertiesToFetch: vocabularySessionPropertiesToFetch,
                deckPropertiesToFetch: vocabularyDeckPropertiesToFetch
            )
        )
    }

    private init(vocabularySummary: StatisticsVocabularySummary) {
        self.vocabularySummary = vocabularySummary
    }

    var hasAnyData: Bool {
        vocabularySummary.hasSessions
    }
}

struct StatisticsVocabularySummary: Equatable {
    let rows: [StatisticsVocabularyDeckRow]

    static let empty = StatisticsVocabularySummary(rows: [])

    static func make(
        modelContext: ModelContext,
        calendar: Calendar,
        now: Date,
        sessionPropertiesToFetch: [PartialKeyPath<VocabularyStudySession>],
        deckPropertiesToFetch: [PartialKeyPath<VocabularyDeck>]
    ) throws -> StatisticsVocabularySummary {
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return .empty
        }

        var sessionDescriptor = FetchDescriptor<VocabularyStudySession>(
            predicate: #Predicate<VocabularyStudySession> { session in
                session.endedAt >= startOfDay && session.endedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        sessionDescriptor.propertiesToFetch = sessionPropertiesToFetch

        let decks = try modelContext.fetchVocabularyDecks(propertiesToFetch: deckPropertiesToFetch)
        return StatisticsVocabularySummary(
            sessions: try modelContext.fetch(sessionDescriptor),
            deckTitleByID: Dictionary(uniqueKeysWithValues: decks.map { ($0.id, $0.title) })
        )
    }

    init(sessions: [VocabularyStudySession], deckTitleByID: [UUID: String]) {
        var accumulatorByDeckID: [UUID: StatisticsVocabularyDeckAccumulator] = [:]
        for session in sessions {
            guard Self.learningKinds.contains(session.kind) || Self.testKinds.contains(session.kind) else {
                continue
            }
            accumulatorByDeckID[session.deckID, default: StatisticsVocabularyDeckAccumulator()].add(session)
        }

        rows = accumulatorByDeckID.map { deckID, accumulator in
            StatisticsVocabularyDeckRow(
                id: deckID,
                deckTitle: deckTitleByID[deckID] ?? "已删除词集",
                learningDuration: accumulator.learningDuration,
                learningMetrics: accumulator.learningMetrics,
                testDuration: accumulator.testDuration,
                testMetrics: accumulator.testMetrics
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalDuration != rhs.totalDuration {
                return lhs.totalDuration > rhs.totalDuration
            }
            return lhs.deckTitle.localizedStandardCompare(rhs.deckTitle) == .orderedAscending
        }
    }

    private init(rows: [StatisticsVocabularyDeckRow]) { self.rows = rows }

    static let learningKinds: Set<String> = ["学习"]
    static let testKinds: Set<String> = ["测验", "英文释义手写", "test"]

    var hasSessions: Bool {
        !rows.isEmpty
    }
}

struct StatisticsVocabularyDeckRow: Identifiable, Equatable {
    let id: UUID
    let deckTitle: String
    let learningDuration: Double
    let learningMetrics: VocabularyStudySessionMetrics
    let testDuration: Double
    let testMetrics: VocabularyStudySessionMetrics

    var totalDuration: Double { learningDuration + testDuration }

    var hasLearning: Bool { learningDuration > 0 || learningMetrics.totalCount > 0 }

    var hasTest: Bool { testDuration > 0 || testMetrics.totalCount > 0 }

    var learningCorrectCount: Int { learningMetrics.correctCount }

    var learningIncorrectCount: Int { max(learningMetrics.totalCount - learningMetrics.correctCount, 0) }

    var learningAccuracy: Double { learningMetrics.accuracy }

    var testCorrectCount: Int { testMetrics.correctCount }

    var testIncorrectCount: Int { max(testMetrics.totalCount - testMetrics.correctCount, 0) }

    var testAccuracy: Double { testMetrics.accuracy }
}

private struct StatisticsVocabularyDeckAccumulator {
    var learningDuration: Double = 0
    var learningMetrics = VocabularyStudySessionMetrics(totalCount: 0, correctCount: 0)
    var testDuration: Double = 0
    var testMetrics = VocabularyStudySessionMetrics(totalCount: 0, correctCount: 0)

    mutating func add(_ session: VocabularyStudySession) {
        let sessionMetrics = VocabularyStudySessionMetrics(
            totalCount: session.totalCount,
            correctCount: session.correctCount
        )
        if StatisticsVocabularySummary.learningKinds.contains(session.kind) {
            learningDuration += max(session.duration, 0)
            learningMetrics = VocabularyStudySessionMetrics.aggregate([
                learningMetrics,
                sessionMetrics
            ])
        } else if StatisticsVocabularySummary.testKinds.contains(session.kind) {
            testDuration += max(session.duration, 0)
            testMetrics = VocabularyStudySessionMetrics.aggregate([
                testMetrics,
                sessionMetrics
            ])
        }
    }
}
