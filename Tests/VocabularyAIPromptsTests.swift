import Foundation

@main
struct VocabularyAIPromptsTests {
    static func main() {
        testSplitPromptContainsJSONContract()
        testDistractorPromptFallsBackForBlankHints()
        testDistractorPromptUsesWeightedBreakdown()
        testHandwritingRecognitionPromptIsAnswerAgnosticAndRequiresVerbatimTranscription()
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

    private static func testHandwritingRecognitionPromptIsAnswerAgnosticAndRequiresVerbatimTranscription() {
        let question = VocabularyAIPrompts.handwritingRecognitionQuestionText(index: 0, hasAnswer: true)
        let missing = VocabularyAIPrompts.handwritingRecognitionQuestionText(index: 1, hasAnswer: false)
        let instruction = VocabularyAIPrompts.handwritingRecognitionInstruction(count: 3, isChinese: false)

        expect(question == "第1题")
        expect(missing == "第2题\n（未作答）")
        expect(!question.contains("题面"))
        expect(!question.contains("正确英文"))
        expect(instruction.contains("只识别"))
        expect(instruction.contains("如实转写"))
        expect(instruction.contains("不要批改、纠正、补全、改写或猜测"))
        expect(instruction.contains("手写英文"))
        expect(instruction.contains("不得擅自添加或删除"))
        expect(instruction.contains("无法可靠识别"))
        expect(instruction.contains("恰好 3 个 items"))
        expect(instruction.contains(#""recognizedText":"student handwriting""#))
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
