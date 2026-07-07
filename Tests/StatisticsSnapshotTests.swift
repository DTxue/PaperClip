import Foundation
import SwiftData

@main
struct StatisticsSnapshotTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            ExamAttempt.self,
            ExamGradeMark.self,
            MistakeCard.self,
            MistakePracticeLayer.self,
            VocabularyDeck.self,
            VocabularyStudySession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(StatisticsSnapshot.cardAggregatePropertiesToFetch.count == 4)
        expect(StatisticsSnapshot.practiceWeekPropertiesToFetch.count == 2)
        expect(StatisticsSnapshot.vocabularySessionPropertiesToFetch.count == 6)
        expect(StatisticsSnapshot.vocabularyDeckPropertiesToFetch.count == 2)
        expect(StatisticsSnapshot.pdfExamAttemptPropertiesToFetch.count == 6)
        expect(StatisticsSnapshot.pdfExamGradeMarkPropertiesToFetch.count == 2)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC
        let lastMonth = try require(calendar.date(byAdding: .month, value: -1, to: now))
        let oldMonth = try require(calendar.date(byAdding: .month, value: -18, to: now))
        let monthBuckets = StatisticsDateBuckets.recentBuckets(
            endingAt: now,
            component: .month,
            count: 3,
            calendar: calendar
        )
        expect(monthBuckets.count == 3)
        expect(monthBuckets.last == StatisticsDateBuckets.bucketStart(
            for: now,
            component: .month,
            calendar: calendar
        ))
        expect(StatisticsDateBuckets.recentBuckets(
            endingAt: now,
            component: .month,
            count: 0,
            calendar: calendar
        ).isEmpty)
        expect(StatisticsDateBuckets.bucketStart(
            for: now,
            component: .weekOfYear,
            calendar: calendar
        ) == calendar.dateInterval(of: .weekOfYear, for: now)?.start)

        let masteredCard = MistakeCard(
            imageFileName: "math-mastered.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: Subject.math.rawValue,
            tagsText: "函数, 一次函数",
            status: MasteryStatus.mastered.rawValue,
            createdAt: now
        )
        let reviewCard = MistakeCard(
            imageFileName: "physics-review.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: Subject.physics.rawValue,
            tagsText: "力学",
            status: MasteryStatus.review.rawValue,
            createdAt: lastMonth
        )
        let oldCard = MistakeCard(
            imageFileName: "old.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: Subject.english.rawValue,
            tagsText: "阅读",
            status: MasteryStatus.unmastered.rawValue,
            createdAt: oldMonth
        )
        let unknownSubjectCard = MistakeCard(
            imageFileName: "unknown.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: "未知学科",
            tagsText: "",
            status: MasteryStatus.mastered.rawValue,
            createdAt: now
        )
        context.insert(masteredCard)
        context.insert(reviewCard)
        context.insert(oldCard)
        context.insert(unknownSubjectCard)

        context.insert(MistakePracticeLayer(
            cardID: masteredCard.id,
            practiceGroupID: UUID(),
            mark: PracticeMark.gotIt.rawValue,
            createdAt: now
        ))
        context.insert(MistakePracticeLayer(
            cardID: reviewCard.id,
            practiceGroupID: UUID(),
            mark: PracticeMark.notYet.rawValue,
            createdAt: now
        ))
        context.insert(MistakePracticeLayer(
            cardID: oldCard.id,
            practiceGroupID: UUID(),
            mark: PracticeMark.gotIt.rawValue,
            createdAt: oldMonth
        ))
        let coreDeckID = UUID()
        let testDeckID = UUID()
        context.insert(VocabularyDeck(id: coreDeckID, title: "核心词集"))
        context.insert(VocabularyDeck(id: testDeckID, title: "测验词集"))
        context.insert(VocabularyStudySession(
            deckID: coreDeckID,
            kind: "学习",
            startedAt: now,
            endedAt: now,
            duration: 60,
            totalCount: 4,
            correctCount: 4,
            items: []
        ))
        context.insert(VocabularyStudySession(
            deckID: coreDeckID,
            kind: "测验",
            startedAt: now,
            endedAt: now,
            duration: 120,
            totalCount: 5,
            correctCount: 3,
            items: []
        ))
        context.insert(VocabularyStudySession(
            deckID: coreDeckID,
            kind: "闪卡",
            startedAt: now,
            endedAt: now,
            duration: 999,
            totalCount: 20,
            correctCount: 20,
            items: []
        ))
        context.insert(VocabularyStudySession(
            deckID: testDeckID,
            kind: "测验",
            startedAt: now,
            endedAt: now,
            duration: 180,
            totalCount: 4,
            correctCount: 4,
            items: []
        ))
        context.insert(VocabularyStudySession(
            deckID: coreDeckID,
            kind: "测验",
            startedAt: oldMonth,
            endedAt: oldMonth,
            duration: 600,
            totalCount: 10,
            correctCount: 0,
            items: []
        ))
        let todayAttemptID = UUID()
        let yesterdayAttemptID = UUID()
        let draftAttemptID = UUID()
        context.insert(ExamAttempt(
            id: todayAttemptID,
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "期中 PDF",
            generatedPDFFileName: "today-exam.pdf",
            selectedPageIndices: [0, 1],
            status: ExamAttemptStatus.graded.rawValue,
            createdAt: try require(calendar.date(byAdding: .minute, value: -35, to: now)),
            submittedAt: try require(calendar.date(byAdding: .minute, value: -5, to: now)),
            updatedAt: now
        ))
        context.insert(ExamAttempt(
            id: yesterdayAttemptID,
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "昨日 PDF",
            generatedPDFFileName: "yesterday-exam.pdf",
            selectedPageIndices: [0],
            status: ExamAttemptStatus.graded.rawValue,
            createdAt: oldMonth,
            submittedAt: oldMonth,
            updatedAt: oldMonth
        ))
        context.insert(ExamAttempt(
            id: draftAttemptID,
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "未批阅 PDF",
            generatedPDFFileName: "draft-exam.pdf",
            selectedPageIndices: [0],
            status: ExamAttemptStatus.inProgress.rawValue,
            createdAt: now,
            submittedAt: nil,
            updatedAt: now
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: UUID(),
            attemptId: todayAttemptID,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.5,0.5"
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: UUID(),
            attemptId: todayAttemptID,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.6,0.5"
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: UUID(),
            attemptId: todayAttemptID,
            pageIndex: 1,
            isCorrect: false,
            normalizedAnchor: "0.5,0.6"
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: UUID(),
            attemptId: yesterdayAttemptID,
            pageIndex: 0,
            isCorrect: false,
            normalizedAnchor: "0.4,0.4"
        ))
        try context.save()

        let snapshot = try StatisticsSnapshot.load(
            modelContext: context,
            calendar: calendar,
            now: now
        )

        expect(snapshot.masterySummary.total == 4)
        expect(snapshot.masterySummary.mastered == 2)
        expect(snapshot.masterySummary.review == 1)
        expect(snapshot.masterySummary.unmastered == 1)
        expect(snapshot.subjectData.map(\.subject) == [
            Subject.math.rawValue,
            Subject.english.rawValue,
            Subject.physics.rawValue
        ])
        expect(snapshot.monthlyData.count == 12)
        expect(snapshot.monthlyData.reduce(0) { $0 + $1.count } == 3)
        expect(snapshot.monthlyData.contains(where: \.hasEntries))
        expect(snapshot.topTags.count == 4)
        expect(Set(snapshot.topTags.map(\.tag)) == ["函数", "一次函数", "力学", "阅读"])
        expect(snapshot.practiceWeekData.count == 1)
        expect(snapshot.practiceWeekData[0].gotIt == 1)
        expect(snapshot.practiceWeekData[0].notYet == 1)
        expect(snapshot.practiceWeekData[0].hasEntries)
        expect(snapshot.vocabularySummary.hasSessions)
        expect(snapshot.vocabularySummary.rows.count == 2)
        expect(Set(snapshot.vocabularySummary.rows.map(\.deckTitle)) == ["测验词集", "核心词集"])
        let testRow = try require(snapshot.vocabularySummary.rows.first { $0.id == testDeckID })
        expect(testRow.learningDuration == 0)
        expect(testRow.learningMetrics.totalCount == 0)
        expect(!testRow.hasLearning)
        expect(testRow.testDuration == 180)
        expect(testRow.testMetrics.totalCount == 4)
        expect(testRow.testCorrectCount == 4)
        expect(testRow.testIncorrectCount == 0)
        let coreRow = try require(snapshot.vocabularySummary.rows.first { $0.id == coreDeckID })
        expect(coreRow.learningDuration == 60)
        expect(coreRow.learningMetrics.totalCount == 4)
        expect(coreRow.learningCorrectCount == 4)
        expect(coreRow.learningIncorrectCount == 0)
        expect(coreRow.testDuration == 120)
        expect(coreRow.testMetrics.totalCount == 5)
        expect(coreRow.testCorrectCount == 3)
        expect(coreRow.testIncorrectCount == 2)
        expect(abs(coreRow.testAccuracy - 0.6) < 0.0001)
        expect(snapshot.pdfExamSummary.hasAttempts)
        expect(snapshot.pdfExamSummary.rows.count == 1)
        let pdfRow = try require(snapshot.pdfExamSummary.rows.first)
        expect(pdfRow.title == "期中 PDF")
        expect(pdfRow.duration == 1_800)
        expect(pdfRow.correctCount == 2)
        expect(pdfRow.incorrectCount == 1)
        expect(abs(pdfRow.accuracy - (2.0 / 3.0)) < 0.0001)
        expect(snapshot.hasAnyData)

        print("StatisticsSnapshotTests: 47 passed")
    }

    private static func require<T>(_ value: T?) throws -> T {
        guard let value else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
