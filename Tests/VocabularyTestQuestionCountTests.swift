import Foundation

@main
struct VocabularyTestQuestionCountTests {
    static func main() {
        testClampedQuestionCountBounds()
        testMinimumQuestionCountUsesTenOrAvailableTotal()
        testClampedQuestionCountRespectsMinimum()
        testBatchCardCountsAreSummedBeforeClamping()
        testSliderRequiresNonDegenerateRange()
        testSelectableRangeSupportsDiscreteAdjustment()
        testDebugModeUsesExactlyFiveQuestions()
        testDebugModeDoesNotRecordHistory()
        testDebugModeRequiresFiveCards()
        testEnglishDefinitionHandwritingUsesStoredDefinition()
        testEnglishDefinitionHandwritingRequiresStoredDefinition()
        testEnglishDefinitionHandwritingOffersCustomAndRandomModes()
        testEnglishDefinitionQuestionCountUsesFixedMinimum()
        testSessionSelectionStrategiesResolveTheirOwnQuestionCounts()
        testSpellingHandwritingKeepsExistingPromptAndAnswer()
        print("VocabularyTestQuestionCountTests: 71 passed")
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

    private static func testMinimumQuestionCountUsesTenOrAvailableTotal() {
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 1) == 1)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 2) == 2)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 3) == 3)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 5) == 5)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.minimum(maximumQuestionCount: 100) == 10)
    }

    private static func testClampedQuestionCountRespectsMinimum() {
        expect(VocabularyTestQuestionCount.clamped(1, maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.clamped(5, maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.clamped(7, maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.clamped(12, maximumQuestionCount: 10) == 10)
        expect(VocabularyTestQuestionCount.clamped(1, maximumQuestionCount: 3) == 3)
        expect(VocabularyTestQuestionCount.clamped(6, maximumQuestionCount: 100) == 10)
    }

    private static func testSliderRequiresNonDegenerateRange() {
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 0))
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 1))
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 9))
        expect(!VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 10))
        expect(VocabularyTestQuestionCount.allowsSlider(maximumQuestionCount: 11))
    }

    private static func testSelectableRangeSupportsDiscreteAdjustment() {
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 100) == 10...100
        )
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 10) == 10...10
        )
        expect(
            VocabularyTestQuestionCount.selectableRange(maximumQuestionCount: 3) == 3...3
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

    private static func testEnglishDefinitionHandwritingOffersCustomAndRandomModes() {
        expect(VocabularyEnglishDefinitionTestMode.allCases == [.custom, .random])
        expect(VocabularyEnglishDefinitionTestMode.custom.rawValue == "自定义选择")
        expect(VocabularyEnglishDefinitionTestMode.random.rawValue == "随机检测")
    }

    private static func testEnglishDefinitionQuestionCountUsesFixedMinimum() {
        expect(VocabularyEnglishDefinitionQuestionCount.minimum == 5)
        expect(!VocabularyEnglishDefinitionQuestionCount.canStart(availableQuestionCount: 4))
        expect(VocabularyEnglishDefinitionQuestionCount.canStart(availableQuestionCount: 5))
        expect(VocabularyEnglishDefinitionQuestionCount.clamped(1, maximumQuestionCount: 100) == 5)
        expect(VocabularyEnglishDefinitionQuestionCount.clamped(4, maximumQuestionCount: 10) == 5)
        expect(VocabularyEnglishDefinitionQuestionCount.clamped(7, maximumQuestionCount: 10) == 7)
        expect(VocabularyEnglishDefinitionQuestionCount.clamped(80, maximumQuestionCount: 100) == 80)
        expect(VocabularyEnglishDefinitionQuestionCount.clamped(120, maximumQuestionCount: 100) == 100)
        expect(VocabularyEnglishDefinitionQuestionCount.selectableRange(maximumQuestionCount: 4) == 5...5)
        expect(VocabularyEnglishDefinitionQuestionCount.selectableRange(maximumQuestionCount: 5) == 5...5)
        expect(VocabularyEnglishDefinitionQuestionCount.selectableRange(maximumQuestionCount: 100) == 5...100)
        expect(!VocabularyEnglishDefinitionQuestionCount.allowsSlider(maximumQuestionCount: 5))
        expect(VocabularyEnglishDefinitionQuestionCount.allowsSlider(maximumQuestionCount: 6))
    }

    private static func testSessionSelectionStrategiesResolveTheirOwnQuestionCounts() {
        expect(
            VocabularyTestSessionQuestionCountPolicy.standard.resolvedQuestionCount(
                requestedQuestionCount: 1,
                maximumQuestionCount: 100,
                mode: .regular
            ) == 10
        )
        expect(
            VocabularyTestSessionQuestionCountPolicy.standard.resolvedQuestionCount(
                requestedQuestionCount: 1,
                maximumQuestionCount: 100,
                mode: .debug
            ) == 5
        )
        expect(
            VocabularyTestSessionQuestionCountPolicy.englishDefinitionRandom.resolvedQuestionCount(
                requestedQuestionCount: 1,
                maximumQuestionCount: 100,
                mode: .regular
            ) == 5
        )
        expect(
            VocabularyTestSessionQuestionCountPolicy.englishDefinitionRandom.resolvedQuestionCount(
                requestedQuestionCount: 80,
                maximumQuestionCount: 100,
                mode: .regular
            ) == 80
        )
        expect(
            VocabularyTestSessionQuestionCountPolicy.englishDefinitionCustom.resolvedQuestionCount(
                requestedQuestionCount: 5,
                maximumQuestionCount: 100,
                customSelectionCount: 7,
                mode: .regular
            ) == 7
        )
        expect(
            VocabularyTestSessionQuestionCountPolicy.englishDefinitionCustom.resolvedQuestionCount(
                requestedQuestionCount: 5,
                maximumQuestionCount: 5,
                customSelectionCount: 7,
                mode: .regular
            ) == 5
        )
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
