import Foundation

@main
enum VocabularyStudySessionMetricsTests {
    static func main() {
        testBuildsFromCorrectnessSequence()
        testClampsInvalidCounts()
        testAggregatesMetrics()
        print("VocabularyStudySessionMetricsTests: 3 passed")
    }

    private static func testBuildsFromCorrectnessSequence() {
        let metrics = VocabularyStudySessionMetrics(correctness: [true, false, true])

        expect(metrics.totalCount == 3)
        expect(metrics.correctCount == 2)
        expect(metrics.accuracy == 2.0 / 3.0)
        expect(metrics.errorRate == 1.0 / 3.0)
    }

    private static func testClampsInvalidCounts() {
        let negative = VocabularyStudySessionMetrics(totalCount: -3, correctCount: -1)
        expect(negative.totalCount == 0)
        expect(negative.correctCount == 0)
        expect(negative.accuracy == 0)
        expect(negative.errorRate == 0)

        let overCorrect = VocabularyStudySessionMetrics(totalCount: 4, correctCount: 9)
        expect(overCorrect.totalCount == 4)
        expect(overCorrect.correctCount == 4)
        expect(overCorrect.accuracy == 1)
        expect(overCorrect.errorRate == 0)
    }

    private static func testAggregatesMetrics() {
        let aggregate = VocabularyStudySessionMetrics.aggregate([
            VocabularyStudySessionMetrics(totalCount: 3, correctCount: 2),
            VocabularyStudySessionMetrics(totalCount: 2, correctCount: 1)
        ])

        expect(aggregate.totalCount == 5)
        expect(aggregate.correctCount == 3)
        expect(aggregate.accuracy == 0.6)
        expect(aggregate.errorRate == 0.4)
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
