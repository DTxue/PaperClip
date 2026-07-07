import Foundation

@main
struct VocabularyDistractorReplacementTests {
    static func main() {
        generatedCacheCarriesCardSnapshot()
        print("VocabularyDistractorReplacementTests: 1 passed")
    }

    private static func generatedCacheCarriesCardSnapshot() {
        let cardID = UUID()
        let deckID = UUID()
        let cache = VocabularyGeneratedDistractorCache(
            cardID: cardID,
            deckID: deckID,
            correctTiles: ["run", "running"],
            distractorTiles: ["ran", "runner"],
            cardTermSnapshot: "running"
        )

        assertEqual(cache.cardID, cardID)
        assertEqual(cache.deckID, deckID)
        assertEqual(cache.correctTiles, ["run", "running"])
        assertEqual(cache.distractorTiles, ["ran", "runner"])
        assertEqual(cache.cardTermSnapshot, "running")
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if actual != expected {
            fatalError("Expected \(expected), got \(actual)", file: file, line: line)
        }
    }
}
