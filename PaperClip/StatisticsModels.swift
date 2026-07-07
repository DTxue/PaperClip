import Foundation
import SwiftData

struct StatisticsSnapshot {
    static var cardAggregatePropertiesToFetch: [PartialKeyPath<MistakeCard>] {
        [\.status, \.subject, \.createdAt, \.tagsText]
    }

    static var practiceWeekPropertiesToFetch: [PartialKeyPath<MistakePracticeLayer>] {
        [\.createdAt, \.mark]
    }

    static var vocabularySessionPropertiesToFetch: [PartialKeyPath<VocabularyStudySession>] {
        [\.deckID, \.kind, \.endedAt, \.duration, \.totalCount, \.correctCount]
    }

    static var vocabularyDeckPropertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.title]
    }

    static var pdfExamAttemptPropertiesToFetch: [PartialKeyPath<ExamAttempt>] {
        [\.id, \.sourceDocumentTitle, \.status, \.createdAt, \.submittedAt, \.updatedAt]
    }

    static var pdfExamGradeMarkPropertiesToFetch: [PartialKeyPath<ExamGradeMark>] {
        [\.attemptId, \.isCorrect]
    }

    let masterySummary: MasteryStatusSummary
    let subjectData: [(subject: String, count: Int)]
    let monthlyData: [StatisticsMonthPoint]
    let topTags: [(tag: String, count: Int)]
    let practiceWeekData: [StatisticsWeekPoint]
    let vocabularySummary: StatisticsVocabularySummary
    let pdfExamSummary: StatisticsPDFExamSummary

    static let empty = StatisticsSnapshot(
        masterySummary: .empty,
        subjectData: [],
        monthlyData: [],
        topTags: [],
        practiceWeekData: [],
        vocabularySummary: .empty,
        pdfExamSummary: .empty
    )

    static func load(
        modelContext: ModelContext,
        calendar: Calendar = .current,
        now: Date = .now
    ) throws -> StatisticsSnapshot {
        let cardAggregate = try StatisticsCardAggregate.make(
            modelContext: modelContext,
            calendar: calendar,
            now: now,
            propertiesToFetch: cardAggregatePropertiesToFetch
        )
        return StatisticsSnapshot(
            masterySummary: cardAggregate.masterySummary,
            subjectData: cardAggregate.subjectData,
            monthlyData: cardAggregate.monthlyData,
            topTags: cardAggregate.topTags,
            practiceWeekData: try StatisticsPracticeWeekData.make(
                modelContext: modelContext,
                calendar: calendar,
                now: now,
                propertiesToFetch: practiceWeekPropertiesToFetch
            ),
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
        masterySummary: MasteryStatusSummary,
        subjectData: [(subject: String, count: Int)],
        monthlyData: [StatisticsMonthPoint],
        topTags: [(tag: String, count: Int)],
        practiceWeekData: [StatisticsWeekPoint],
        vocabularySummary: StatisticsVocabularySummary,
        pdfExamSummary: StatisticsPDFExamSummary
    ) {
        self.masterySummary = masterySummary
        self.subjectData = subjectData
        self.monthlyData = monthlyData
        self.topTags = topTags
        self.practiceWeekData = practiceWeekData
        self.vocabularySummary = vocabularySummary
        self.pdfExamSummary = pdfExamSummary
    }

    var hasAnyData: Bool {
        masterySummary.total > 0 || vocabularySummary.hasSessions || pdfExamSummary.hasAttempts
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
    static let testKinds: Set<String> = ["测验", "test"]

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
        var metricByAttemptID: [UUID: PDFExamMetric] = [:]
        for mark in marks where attemptIDSet.contains(mark.attemptId) {
            metricByAttemptID[mark.attemptId, default: PDFExamMetric()].add(isCorrect: mark.isCorrect)
        }

        var accumulatorByTitle: [String: StatisticsPDFExamAccumulator] = [:]
        for attempt in attempts {
            var accumulator = accumulatorByTitle[attempt.sourceDocumentTitle, default: StatisticsPDFExamAccumulator()]
            accumulator.duration += Self.duration(for: attempt)
            accumulator.metric.add(metricByAttemptID[attempt.id, default: PDFExamMetric()])
            accumulatorByTitle[attempt.sourceDocumentTitle] = accumulator
        }

        rows = accumulatorByTitle.map { title, accumulator in
            StatisticsPDFExamRow(
                id: title,
                title: title,
                duration: accumulator.duration,
                correctCount: accumulator.metric.correctCount,
                incorrectCount: accumulator.metric.incorrectCount
            )
        }
        .sorted { lhs, rhs in
            if lhs.duration != rhs.duration { return lhs.duration > rhs.duration }
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
    let id: String
    let title: String
    let duration: Double
    let correctCount: Int
    let incorrectCount: Int

    var totalCount: Int { correctCount + incorrectCount }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
}

private struct StatisticsPDFExamAccumulator {
    var duration: Double = 0
    var metric = PDFExamMetric()
}

private struct PDFExamMetric {
    var correctCount: Int = 0
    var incorrectCount: Int = 0

    mutating func add(isCorrect: Bool) {
        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
    }

    mutating func add(_ other: PDFExamMetric) {
        correctCount += other.correctCount
        incorrectCount += other.incorrectCount
    }
}
