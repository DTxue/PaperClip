import Foundation

@main
struct VocabularyAnswerCheckerTests {
    static func main() {
        let card = VocabularyCard(
            deckID: UUID(),
            term: "cafe",
            definition: "咖啡馆",
            alternativeAnswersText: " café | coffee shop | "
        )

        expect(VocabularyAnswerChecker.isCorrect(" CAFÉ ", for: card, direction: .definitionToTerm))
        expect(VocabularyAnswerChecker.isCorrect("coffee   shop", for: card, direction: .definitionToTerm))
        expect(VocabularyAnswerChecker.isCorrect(" 咖啡馆。", for: card, direction: .termToDefinition))
        expect(!VocabularyAnswerChecker.isCorrect("coffee", for: card, direction: .termToDefinition))

        print("VocabularyAnswerCheckerTests: 4 passed")
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
