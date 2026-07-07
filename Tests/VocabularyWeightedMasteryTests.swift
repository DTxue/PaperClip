import Foundation

@main
struct VocabularyWeightedMasteryTests {
    static func main() {
        testSortedNewestFirstCalculatorMatchesSortingCalculator()
        testSortedNewestFirstCalculatorUsesRecentMatchingLogs()
        print("VocabularyWeightedMasteryTests: 2 passed")
    }

    private static func testSortedNewestFirstCalculatorMatchesSortingCalculator() {
        let deckID = UUID()
        let cardID = UUID()
        let newestFirst = [
            log(cardID: cardID, deckID: deckID, responseKind: "测验-拼写", rating: .good, secondsAgo: 10),
            log(cardID: cardID, deckID: deckID, responseKind: "闪卡", rating: .again, secondsAgo: 20),
            log(cardID: cardID, deckID: deckID, responseKind: "拼句", rating: .easy, secondsAgo: 30),
            log(cardID: cardID, deckID: deckID, responseKind: "闪卡", rating: .good, secondsAgo: 40)
        ]
        let unsorted = [newestFirst[2], newestFirst[0], newestFirst[3], newestFirst[1]]

        let sortedResult = VocabularyWeightedMasteryCalculator.calculate(
            sortedNewestFirstLogs: newestFirst,
            recentCount: 20
        )
        let sortingResult = VocabularyWeightedMasteryCalculator.calculate(logs: unsorted, recentCount: 20)

        expect(sortedResult.flashcardAccuracy == sortingResult.flashcardAccuracy)
        expect(sortedResult.studyAccuracy == sortingResult.studyAccuracy)
        expect(sortedResult.quizAccuracy == sortingResult.quizAccuracy)
        expect(sortedResult.weightedMastery == sortingResult.weightedMastery)
    }

    private static func testSortedNewestFirstCalculatorUsesRecentMatchingLogs() {
        let deckID = UUID()
        let cardID = UUID()
        let logs = [
            log(cardID: cardID, deckID: deckID, responseKind: "闪卡", rating: .good, secondsAgo: 10),
            log(cardID: cardID, deckID: deckID, responseKind: "拼句", rating: .easy, secondsAgo: 20),
            log(cardID: cardID, deckID: deckID, responseKind: "闪卡", rating: .again, secondsAgo: 30),
            log(cardID: cardID, deckID: deckID, responseKind: "闪卡", rating: .easy, secondsAgo: 40)
        ]

        let result = VocabularyWeightedMasteryCalculator.calculate(
            sortedNewestFirstLogs: logs,
            recentCount: 2
        )

        expect(result.flashcardAccuracy == 0.5)
        expect(result.studyAccuracy == 1)
    }

    private static func log(
        cardID: UUID,
        deckID: UUID,
        responseKind: String,
        rating: VocabularyReviewRating,
        secondsAgo: TimeInterval
    ) -> VocabularyReviewLog {
        VocabularyReviewLog(
            cardID: cardID,
            deckID: deckID,
            direction: .termToDefinition,
            rating: rating,
            responseKind: responseKind,
            duration: 1,
            reviewedAt: Date(timeIntervalSince1970: 10_000 - secondsAgo),
            previousStability: 0,
            resultingStability: 0
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
