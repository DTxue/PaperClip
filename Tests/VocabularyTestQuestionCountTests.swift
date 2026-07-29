import Foundation

@main
struct VocabularyTestQuestionCountTests {
    static func main() {
        testClampedQuestionCountBounds()
        testMinimumQuestionCountUsesSixtyPercent()
        testClampedQuestionCountRespectsMinimum()
        testBatchCardCountsAreSummedBeforeClamping()
        testSliderRequiresNonDegenerateRange()
        testSelectableRangeSupportsDiscreteAdjustment()
        testDebugModeUsesExactlyFiveQuestions()
        testDebugModeDoesNotRecordHistory()
        testDebugModeRequiresFiveCards()
        testEnglishDefinitionHandwritingUsesStoredDefinition()
        testEnglishDefinitionHandwritingRequiresStoredDefinition()
        testSpellingHandwritingKeepsExistingPromptAndAnswer()
        print("VocabularyTestQuestionCountTests: 49 passed")
    }

    private static func testClampedQuestionCountBounds() {
        expect(VocabularyTestQuestionCount.clamped(-3) == 1)
        expect(VocabularyTestQuestionCount.clamped(0) == 1)
        expect(VocabularyTestQuestionCount.clamped(1) == 1)
        expect(VocabularyTestQuestionCount.clamped(7) == 7)
        expect(VocabularyTestQuestionCount.clamped(100) == 100)
    }

    private static func testBatchCardCountsAreSummedBeforeClamping() {
        expect(VocabularyTestQuestionCount.maximum(inBatchCardCounts: []) == 1)
        expect(VocabularyTestQuestionCount.maximum(inBatchCardCounts: [2, 3, 6]) == 11)
    }

    private static func testMinimumQuestionCountUsesSixtyPercent() {
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 1) == 1)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 2) == 2)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 3) == 2)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 5) == 3)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 10) == 6)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 100) == 60)
    }

    private static func testClampedQuestionCountRespectsMinimum() {
        expect(VocabularyTestQuestionCount.clamped(1, maximumQuestionCount: 10) == 6)
        expect(VocabularyTestQuestionCount.clamped(5, maximumQuestionCount: 10) == 6)
        expect(VocabularyTestQuestionCount.clamped(7, maximumQuestionCount: 10) == 7)
        expect(VocabularyTestQuestionCount.clamped(12, maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.clamped(1, maximumQuestionCount: 3) == 2)
        expect(VocabularyTestQuestionCount.clamped(6, maximumQuestionCount: 100) == 60)
    }

    private static func testSliderRequiresNonDegenerateRange() {
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 0))
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 1))
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 2))
        expect(VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 3))
    }

    private static func testSelectableRangeSupportsDiscreteAdjustment() {
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 10) == 6...10
        )
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 3) == 2...3
        )
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 1) == 1...1
        )
    }

    private static func testDebugModeUsesExactlyFiveQuestions() {
        expect(
            VocabularyTestMode.debug.resolvedQuestionCount(
                requestedQuestionCount: 1,
                maximumQuestionCount: 20
            ) == 5
        )
        expect(
            VocabularyTestMode.debug.resolvedQuestionCount(
                requestedQuestionCount: 1,
                maximumQuestionCount: 4
            ) == 5
        )
        expect(VocabularyTestMode.debug.minimumRequiredCardCount == 5)
    }

    private static func testDebugModeDoesNotRecordHistory() {
        expect(VocabularyTestMode.regular.recordsHistory)
        expect(VocabularyTestMode.exam.recordsHistory)
        expect(!VocabularyTestMode.debug.recordsHistory)
    }

    private static func testDebugModeRequiresFiveCards() {
        expect(!VocabularyTestMode.debug.canStart(cardCount: 4))
        expect(VocabularyTestMode.debug.canStart(cardCount: 5))
        expect(VocabularyTestMode.regular.canStart(cardCount: 1))
        expect(VocabularyTestMode.setupModes == [.regular, .debug])
    }

    private static func testEnglishDefinitionHandwritingUsesStoredDefinition() {
        let kind = VocabularyHandwritingTestKind.englishDefinition

        expect(
            kind.prompt(
                term: "deliberate",
                definition: "深思熟虑的"
            ) == "deliberate"
        )
        expect(
            kind.referenceAnswer(
                term: "deliberate",
                englishDefinition: "done consciously and intentionally"
            ) == "done consciously and intentionally"
        )
        expect(kind.reviewResponseKind == "测验-英文释义手写")
        expect(kind.reviewDirection == .termToDefinition)
    }

    private static func testEnglishDefinitionHandwritingRequiresStoredDefinition() {
        let kind = VocabularyHandwritingTestKind.englishDefinition

        expect(!kind.isEligible(englishDefinition: nil))
        expect(!kind.isEligible(englishDefinition: ""))
        expect(!kind.isEligible(englishDefinition: "   \n"))
        expect(kind.isEligible(englishDefinition: "a short pause"))
    }

    private static func testSpellingHandwritingKeepsExistingPromptAndAnswer() {
        let kind = VocabularyHandwritingTestKind.spelling

        expect(kind.prompt(term: "pause", definition: "暂停") == "暂停")
        expect(
            kind.referenceAnswer(
                term: "pause",
                englishDefinition: "to stop briefly"
            ) == "pause"
        )
        expect(kind.isEligible(englishDefinition: nil))
        expect(kind.reviewResponseKind == "测验-手写")
        expect(kind.reviewDirection == .definitionToTerm)
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
