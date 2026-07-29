import Foundation

@main
struct VocabularyFlashcardReviewItemFactoryTests {
    static func main() {
        testPromptAndAnswerFollowDirection()
        testReviewItemUsesRatingOutcome()
        testWordBankItemUsesPlacedWords()
        testHandwritingItemHidesRecognizedTextForCorrectAnswer()
        testEnglishDefinitionHandwritingStoresReferenceAndRecognition()
        print("VocabularyFlashcardReviewItemFactoryTests: 15 passed")
    }

    private static func testPromptAndAnswerFollowDirection() {
        let card = makeCard()

        expect(
            VocabularyStudySessionItemFactory.prompt(for: card, direction: .termToDefinition) == "photosynthesis"
        )
        expect(
            VocabularyStudySessionItemFactory.answer(for: card, direction: .termToDefinition) == "光合作用"
        )
        expect(
            VocabularyStudySessionItemFactory.prompt(for: card, direction: .definitionToTerm) == "光合作用"
        )
        expect(
            VocabularyStudySessionItemFactory.answer(for: card, direction: .definitionToTerm) == "photosynthesis"
        )
    }

    private static func testReviewItemUsesRatingOutcome() {
        let card = makeCard()

        let againItem = VocabularyStudySessionItemFactory.makeFlashcardReview(
            card: card,
            direction: .termToDefinition,
            rating: .again
        )
        expect(!againItem.isCorrect)
        expect(againItem.comment == VocabularyReviewRating.again.title)

        let goodItem = VocabularyStudySessionItemFactory.makeFlashcardReview(
            card: card,
            direction: .definitionToTerm,
            rating: .good
        )
        expect(goodItem.isCorrect)
        expect(goodItem.prompt == "光合作用")
        expect(goodItem.expectedAnswer == "photosynthesis")
    }

    private static func testWordBankItemUsesPlacedWords() {
        let item = VocabularyStudySessionItemFactory.makeWordBankAnswer(
            card: makeCard(),
            placedWords: ["photo", "synthesis"],
            isCorrect: false
        )

        expect(item.prompt == "光合作用")
        expect(item.expectedAnswer == "photosynthesis")
        expect(item.recognizedText == "photo synthesis")
        expect(item.comment == "拼句错误")
    }

    private static func testHandwritingItemHidesRecognizedTextForCorrectAnswer() {
        let correctItem = VocabularyStudySessionItemFactory.makeHandwritingTestAnswer(
            card: makeCard(),
            isCorrect: true,
            recognizedText: "photosyntesis",
            comment: "可接受"
        )
        expect(correctItem.recognizedText.isEmpty)

        let wrongItem = VocabularyStudySessionItemFactory.makeHandwritingTestAnswer(
            card: makeCard(),
            isCorrect: false,
            recognizedText: "photosyntesis",
            comment: "拼写错误"
        )
        expect(wrongItem.recognizedText == "photosyntesis")
        expect(wrongItem.comment == "拼写错误")
    }

    private static func testEnglishDefinitionHandwritingStoresReferenceAndRecognition() {
        let item = VocabularyStudySessionItemFactory.makeHandwritingTestAnswer(
            card: makeCard(),
            prompt: "photosynthesis",
            expectedAnswer: "the way plants use light to make food",
            isCorrect: true,
            recognizedText: "The way plants use light to make food.",
            comment: "正确",
            keepsRecognizedTextForCorrectAnswer: true
        )

        expect(item.prompt == "photosynthesis")
        expect(item.expectedAnswer == "the way plants use light to make food")
        expect(item.recognizedText == "The way plants use light to make food.")
        expect(item.isCorrect)
    }

    private static func makeCard() -> VocabularyCard {
        VocabularyCard(
            id: UUID(uuidString: "3BE74669-B379-4CC5-8AC4-6C5A2F9D9282")!,
            deckID: UUID(uuidString: "59C197E1-930E-43D7-80B1-821926A470B5")!,
            term: "photosynthesis",
            definition: "光合作用"
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
