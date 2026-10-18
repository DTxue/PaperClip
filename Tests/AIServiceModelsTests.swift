import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Test failed: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

@main
struct AIServiceModelsTests {
    static func main() throws {
        try testVocabularyGradingDefaults()
        try testVocabularyGradingOutputTokenBudgetScalesWithQuestionCount()
        try testKnowledgeRequestConfiguration()
        try testFixedProviderRequestConfiguration()

        print("AIServiceModelsTests: passed")
    }

    private static func testVocabularyGradingDefaults() throws {
        let data = """
        { "index": 1, "isCorrect": false }
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(VocabularyGradingItem.self, from: data)
        expect(value.comment.isEmpty, "defaults missing comment")
        expect(value.recognizedText.isEmpty, "defaults missing recognized text")
    }

    private static func testVocabularyGradingOutputTokenBudgetScalesWithQuestionCount() throws {
        expect(
            VocabularyGradingOutputBudget.maxTokens(questionCount: 0) == 512,
            "empty grading requests keep the minimum output budget"
        )
        expect(
            VocabularyGradingOutputBudget.maxTokens(questionCount: 6) > 512,
            "six-question grading output should not use the old truncation-prone 512 token budget"
        )
        expect(
            VocabularyGradingOutputBudget.maxTokens(questionCount: 60) <= 8_192,
            "large grading batches should stay under the app's normal doubao answer token ceiling"
        )
    }

    private static func testKnowledgeRequestConfiguration() throws {
        let doubao = AIRequestConfiguration.knowledge(model: .doubao, taskName: "知识提取")
        expect(doubao.thinking == "disabled", "doubao knowledge requests should not enable thinking")
        expect(doubao.maxOutputTokens == 2_048, "doubao knowledge token budget should preserve existing behavior")
        expect(doubao.modelName == "豆包知识提取", "doubao knowledge model name should combine short title and task")

        let deepSeek = AIRequestConfiguration.knowledge(model: .deepSeek, taskName: "知识解析")
        expect(deepSeek.thinking == "disabled", "deepSeek knowledge requests should stay non-thinking")
        expect(deepSeek.maxOutputTokens == 2_048, "deepSeek knowledge token budget should preserve existing behavior")
        expect(deepSeek.modelName == "DeepSeek知识解析", "deepSeek knowledge model name should combine short title and task")
    }

    private static func testFixedProviderRequestConfiguration() throws {
        let deepSeek = AIRequestConfiguration.deepSeek(
            modelName: "DeepSeek 通用任务",
            maxOutputTokens: 4_096
        )
        expect(deepSeek.model == .deepSeek, "deepSeek helper should pin deepSeek model")
        expect(deepSeek.usesDeepThinking, "deepSeek helper should enable thinking")

        let doubao = AIRequestConfiguration.doubao(
            modelName: "豆包图片识别",
            maxOutputTokens: 8_192
        )
        expect(doubao.model == .doubao, "doubao helper should pin doubao model")
        expect(!doubao.usesDeepThinking, "doubao helper should disable thinking")
    }
}
