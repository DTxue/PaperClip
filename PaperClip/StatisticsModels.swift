import Foundation
import SwiftData

struct StatisticsSnapshot {
    static var vocabularySessionPropertiesToFetch: [PartialKeyPath<VocabularyStudySession>] {
        [\.deckID, \.kind, \.endedAt, \.duration, \.totalCount, \.correctCount]
    }

    static var vocabularyDeckPropertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.title]
    }

    static var pdfExamAttemptPropertiesToFetch: [PartialKeyPath<ExamAttempt>] {
        [\.id, \.sourceDocumentId, \.sourceDocumentTitle, \.status, \.createdAt, \.submittedAt, \.updatedAt]
    }

    static var pdfExamGradeMarkPropertiesToFetch: [PartialKeyPath<ExamGradeMark>] {
        [\.attemptId, \.isCorrect]
    }

    let vocabularySummary: StatisticsVocabularySummary
    let pdfExamSummary: StatisticsPDFExamSummary

    static let empty = StatisticsSnapshot(
        vocabularySummary: .empty,
        pdfExamSummary: .empty
    )

    static func load(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        now: Date = .now
    ) throws -> StatisticsSnapshot {
        return StatisticsSnapshot(
            vocabularySummary: try StatisticsVocabularySummary.make(
                modelContext: modelContext,
                calendar: calendar,
                now: now,
                sessionPropertiesToFetch: vocabularySessionPropertiesToFetch,
                deckPropertiesToFetch: vocabularyDeckPropertiesToFetch
            ),
            pdfExamSummary: try StatisticsPDFExamSummary.make(
                modelContext: modelContext,
                calendar: calendar,
                now: now,
                attemptPropertiesToFetch: pdfExamAttemptPropertiesToFetch,
                gradeMarkPropertiesToFetch: pdfExamGradeMarkPropertiesToFetch
            )
        )
    }

    private init(
        vocabularySummary: StatisticsVocabularySummary,
        pdfExamSummary: StatisticsPDFExamSummary
    ) {
        self.vocabularySummary = vocabularySummary
        self.pdfExamSummary = pdfExamSummary
    }

    var hasAnyData: Bool {
        vocabularySummary.hasSessions || pdfExamSummary.hasAttempts
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

struct StatisticsPDFExamSummary: Equatable {
    let rows: [StatisticsPDFExamRow]

    static let empty = StatisticsPDFExamSummary(rows: [])

    static func make(
        modelContext: ModelContext,
        calendar: Calendar,
        now: Date,
        attemptPropertiesToFetch: [PartialKeyPath<ExamAttempt>],
        gradeMarkPropertiesToFetch: [PartialKeyPath<ExamGradeMark>]
    ) throws -> StatisticsPDFExamSummary {
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return .empty
        }

        var attemptDescriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.status == "graded"
                    && attempt.updatedAt >= startOfDay
                    && attempt.updatedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        attemptDescriptor.propertiesToFetch = attemptPropertiesToFetch
        let attempts = try modelContext.fetch(attemptDescriptor)
        guard !attempts.isEmpty else { return .empty }

        var markDescriptor = FetchDescriptor<ExamGradeMark>()
        markDescriptor.propertiesToFetch = gradeMarkPropertiesToFetch
        return StatisticsPDFExamSummary(
            attempts: attempts,
            marks: try modelContext.fetch(markDescriptor)
        )
    }

    init(attempts: [ExamAttempt], marks: [ExamGradeMark]) {
        let attemptIDSet = Set(attempts.map(\.id))
        var metricByAttemptID: [UUID: ExamAttemptQuestionMetrics] = [:]
        for mark in marks where attemptIDSet.contains(mark.attemptId) {
            metricByAttemptID[mark.attemptId, default: ExamAttemptQuestionMetrics()].add(isCorrect: mark.isCorrect)
        }

        rows = attempts.map { attempt in
            let metric = metricByAttemptID[attempt.id, default: ExamAttemptQuestionMetrics()]
            return StatisticsPDFExamRow(
                id: attempt.id,
                sourceDocumentID: attempt.sourceDocumentId,
                title: attempt.sourceDocumentTitle,
                completedAt: attempt.updatedAt,
                duration: Self.duration(for: attempt),
                correctCount: metric.correctCount,
                incorrectCount: metric.incorrectCount
            )
        }
        .sorted { lhs, rhs in
            if lhs.completedAt != rhs.completedAt { return lhs.completedAt > rhs.completedAt }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private init(rows: [StatisticsPDFExamRow]) { self.rows = rows }

    private static func duration(for attempt: ExamAttempt) -> Double {
        guard let submittedAt = attempt.submittedAt else { return 0 }
        return max(submittedAt.timeIntervalSince(attempt.createdAt), 0)
    }

    var hasAttempts: Bool { !rows.isEmpty }
}

struct StatisticsPDFExamRow: Identifiable, Equatable {
    let id: UUID
    let sourceDocumentID: UUID
    let title: String
    let completedAt: Date
    let duration: Double
    let correctCount: Int
    let incorrectCount: Int

    var totalCount: Int { correctCount + incorrectCount }

    var averageQuestionDuration: Double? {
        guard totalCount > 0 else { return nil }
        return duration / Double(totalCount)
    }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
}
