import Foundation

@main
enum VocabularyReviewFuzzFactorTests {
    static func main() {
        testFactorIsStableAndBounded()
        testDirectionChangesFactor()
        testNegativeReviewCountMatchesZero()

        print("VocabularyReviewFuzzFactorTests: 3 passed")
    }

    private static func testFactorIsStableAndBounded() {
        let cardID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let first = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .termToDefinition,
            reviewCount: 3
        )
        let second = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .termToDefinition,
            reviewCount: 3
        )

        expect(first == second, "factor should be deterministic")
        expect(first >= 0 && first < 1, "factor should be normalized into [0, 1)")
    }

    private static func testDirectionChangesFactor() {
        let cardID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let termToDefinition = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .termToDefinition,
            reviewCount: 3
        )
        let definitionToTerm = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .definitionToTerm,
            reviewCount: 3
        )

        expect(termToDefinition != definitionToTerm, "direction should affect the deterministic jitter")
    }

    private static func testNegativeReviewCountMatchesZero() {
        let cardID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let negative = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .termToDefinition,
            reviewCount: -1
        )
        let zero = VocabularyReviewFuzzFactor.factor(
            cardID: cardID,
            direction: .termToDefinition,
            reviewCount: 0
        )

        expect(negative == zero, "negative review counts should be clamped to zero")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
