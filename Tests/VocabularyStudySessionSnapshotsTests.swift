import Foundation

@main
struct VocabularyStudySessionSnapshotsTests {
    static func main() {
        testSummaryAggregatesDurationAndAccuracy()
        testScopeTitleHandlesEmptyAndNonPositiveLimits()
        testItemGroupsPreserveCorrectAndIncorrectOrder()
        testDurationFormattingClampsNegativeSeconds()
        print("VocabularyStudySessionSnapshotsTests: passed")
    }

    private static func testSummaryAggregatesDurationAndAccuracy() {
        let summary = VocabularyStudySessionSummary(
            durations: [10, 20, -5],
            metrics: [
                VocabularyStudySessionMetrics(totalCount: 2, correctCount: 1),
                VocabularyStudySessionMetrics(totalCount: 3, correctCount: 3)
            ]
        )

        expect(summary.totalDuration == 25)
        expect(summary.averageAccuracy == 0.8)
    }

    private static func testScopeTitleHandlesEmptyAndNonPositiveLimits() {
        expect(VocabularyStudySessionSummary.scopeTitle(sessionCount: 0, limit: 20) == "全部 0 次")
        expect(VocabularyStudySessionSummary.scopeTitle(sessionCount: 3, limit: 20) == "全部 3 次")
        expect(VocabularyStudySessionSummary.scopeTitle(sessionCount: 20, limit: 20) == "最近 20 次")
        expect(VocabularyStudySessionSummary.scopeTitle(sessionCount: 3, limit: 0) == "全部 3 次")
        expect(VocabularyStudySessionSummary.scopeTitle(sessionCount: 3, limit: -1) == "全部 3 次")
    }

    private static func testItemGroupsPreserveCorrectAndIncorrectOrder() {
        let correctA = makeItem(prompt: "correct-a", isCorrect: true)
        let wrongA = makeItem(prompt: "wrong-a", isCorrect: false)
        let correctB = makeItem(prompt: "correct-b", isCorrect: true)
        let wrongB = makeItem(prompt: "wrong-b", isCorrect: false)

        let groups = VocabularyStudySessionItemGroups(items: [correctA, wrongA, correctB, wrongB])

        expect(groups.correctItems.map(\.prompt) == ["correct-a", "correct-b"])
        expect(groups.incorrectItems.map(\.prompt) == ["wrong-a", "wrong-b"])
    }

    private static func testDurationFormattingClampsNegativeSeconds() {
        expect(VocabularyStudySessionFormat.duration(-4) == "0秒")
        expect(VocabularyStudySessionFormat.duration(65) == "1分5秒")
        expect(VocabularyStudySessionFormat.duration(3_660) == "1小时1分")
    }

    private static func makeItem(prompt: String, isCorrect: Bool) -> VocabularyStudySessionItem {
        VocabularyStudySessionItem(
            cardID: UUID(),
            prompt: prompt,
            expectedAnswer: "answer",
            isCorrect: isCorrect
        )
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
