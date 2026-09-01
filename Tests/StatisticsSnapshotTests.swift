import Foundation
import SwiftData

@main
struct StatisticsSnapshotTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            VocabularyDeck.self,
            VocabularyStudySession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(StatisticsSnapshot.vocabularySessionPropertiesToFetch.count == 6)
        expect(StatisticsSnapshot.vocabularyDeckPropertiesToFetch.count == 2)

        try testVocabularyStudyCompletionAppearsInTodayStatistics()

        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC
        let oldDate = try require(calendar.date(byAdding: .day, value: -1, to: now))
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
            deckID: testDeckID,
            kind: "英文释义手写",
            startedAt: now,
            endedAt: now,
            duration: 30,
            totalCount: 2,
            correctCount: 1,
            items: []
        ))
        context.insert(VocabularyStudySession(
            deckID: coreDeckID,
            kind: "测验",
            startedAt: oldDate,
            endedAt: oldDate,
            duration: 600,
            totalCount: 10,
            correctCount: 0,
            items: []
        ))
        try context.save()

        let snapshot = try StatisticsSnapshot.load(
            modelContext: context,
            calendar: calendar,
            now: now
        )

        expect(snapshot.vocabularySummary.hasSessions)
        expect(snapshot.vocabularySummary.rows.count == 2)
        expect(Set(snapshot.vocabularySummary.rows.map(\.deckTitle)) == ["测验词集", "核心词集"])
        let testRow = try require(snapshot.vocabularySummary.rows.first { $0.id == testDeckID })
        expect(testRow.learningDuration == 0)
        expect(testRow.learningMetrics.totalCount == 0)
        expect(!testRow.hasLearning)
        expect(testRow.testDuration == 210)
        expect(testRow.testMetrics.totalCount == 6)
        expect(testRow.testCorrectCount == 5)
        expect(testRow.testIncorrectCount == 1)
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
        expect(snapshot.hasAnyData)

        print("StatisticsSnapshotTests: passed")
    }

    @MainActor
    private static func testVocabularyStudyCompletionAppearsInTodayStatistics() throws {
        let schema = Schema([
            VocabularyDeck.self,
            VocabularyStudySession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let deck = VocabularyDeck(title: "今日学习词集")
        context.insert(deck)
        try context.save()

        let didRecord = try VocabularyStudySessionTransaction.recordSession(
            deckID: deck.id,
            kind: "学习",
            startedAt: Date.now.addingTimeInterval(-75),
            items: [
                VocabularyStudySessionItem(
                    cardID: UUID(),
                    prompt: "first prompt",
                    expectedAnswer: "first answer",
                    isCorrect: true
                ),
                VocabularyStudySessionItem(
                    cardID: UUID(),
                    prompt: "second prompt",
                    expectedAnswer: "second answer",
                    isCorrect: false
                )
            ],
            in: context
        )
        expect(didRecord)

        let snapshot = try StatisticsSnapshot.load(modelContext: context)
        expect(snapshot.vocabularySummary.hasSessions)
        expect(snapshot.vocabularySummary.rows.count == 1)

        let row = try require(snapshot.vocabularySummary.rows.first)
        expect(row.deckTitle == "今日学习词集")
        expect(row.hasLearning)
        expect(row.learningMetrics.totalCount == 2)
        expect(row.learningCorrectCount == 1)
        expect(row.learningIncorrectCount == 1)
        expect(!row.hasTest)
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
