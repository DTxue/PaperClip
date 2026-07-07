import Foundation

@main
struct VocabularyAIPromptsTests {
    static func main() {
        testSplitPromptContainsJSONContract()
        testDistractorPromptFallsBackForBlankHints()
        testDistractorPromptUsesWeightedBreakdown()
        testGradingQuestionTextMarksMissingAnswer()
        print("VocabularyAIPromptsTests: 4 passed")
    }

    private static func testSplitPromptContainsJSONContract() {
        let prompt = VocabularyAIPrompts.splitCard(term: "take off", definition: "起飞；脱下")

        expect(prompt.contains("英文词条：take off"))
        expect(prompt.contains("中文释义：起飞；脱下"))
        expect(prompt.contains(#"{"cards":[{"term":"...","definition":"..."}]}"#))
    }

    private static func testDistractorPromptFallsBackForBlankHints() {
        let prompt = VocabularyAIPrompts.distractors(
            term: "apple",
            definition: "苹果",
            partOfSpeech: "",
            example: "",
            config: DistractorConfig()
        )

        expect(prompt.contains("词性：不限"))
        expect(prompt.contains("例句：无"))
        expect(prompt.contains("生成恰好 8 个干扰单词"))
    }

    private static func testDistractorPromptUsesWeightedBreakdown() {
        let prompt = VocabularyAIPrompts.distractors(
            term: "run",
            definition: "跑",
            partOfSpeech: "verb",
            example: "I run every day.",
            config: DistractorConfig(totalCount: 5, weightInflection: 0, weightLookalike: 0, weightSynonym: 0, weightConfused: 0, weightDerivation: 0)
        )

        expect(prompt.contains("词性：verb"))
        expect(prompt.contains("例句：I run every day."))
        expect(prompt.contains("生成 5 个干扰单词"))
        expect(!prompt.contains("按以下类型分配"))
    }

    private static func testGradingQuestionTextMarksMissingAnswer() {
        let answered = VocabularyAIPrompts.gradingQuestionText(
            index: 0,
            term: "book",
            definition: "书",
            hasAnswer: true
        )
        let missing = VocabularyAIPrompts.gradingQuestionText(
            index: 1,
            term: "pen",
            definition: "笔",
            hasAnswer: false
        )

        expect(answered == "第1题\n中文含义：书\n正确英文：book")
        expect(missing == "第2题\n中文含义：笔\n正确英文：pen\n（未作答）")
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
