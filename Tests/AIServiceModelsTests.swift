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
        try testExamGradingFlexibleFields()
        try testVocabularyGradingDefaults()
        try testVocabularyGradingOutputTokenBudgetScalesWithQuestionCount()
        try testWritingReviewDisplayText()
        try testWritingReviewJSONStorage()
        try testGoodWordsAndSentencesDecoding()
        try testDiaryRequestConfiguration()
        try testKnowledgeRequestConfiguration()
        try testFixedProviderRequestConfiguration()

        print("AIServiceModelsTests: passed")
    }

    private static func testExamGradingFlexibleFields() throws {
        let data = """
        {
          "items": [
            {
              "pageIndex": "3",
              "questionNumber": 7,
              "isCorrect": true,
              "stampAnchor": { "x": "0.25", "y": 0.75 },
              "confidence": "0.9"
            }
          ]
        }
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(AIExamGradingResult.self, from: data)
        let item = value.items[0]
        expect(item.pageIndex == 3, "decodes string page index")
        expect(item.questionNumber == "7", "decodes numeric question number as string")
        expect(item.stampAnchor.x == 0.25 && item.confidence == 0.9, "decodes flexible doubles")
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

    private static func testWritingReviewDisplayText() throws {
        let topicData = """
        {
          "keywords": ["成长", "责任"],
          "realTask": "写清成长",
          "studentHandling": "",
          "riskOfShallowWriting": "",
          "bestWritingDirection": ""
        }
        """.data(using: .utf8)!
        let topic = try JSONDecoder().decode(
            AIWritingReviewResult.TopicTaskAnalysis.self,
            from: topicData
        )
        expect(topic.keywordsText == "成长、责任", "topic keywords should use shared Chinese list text")

        let sceneData = """
        {
          "scene": "雨中等待",
          "whyThisSceneMatters": "承载变化",
          "detailsToAdd": ["动作", "心理"]
        }
        """.data(using: .utf8)!
        let scene = try JSONDecoder().decode(
            AIWritingReviewResult.WritingBlueprint.CoreSceneToBuild.self,
            from: sceneData
        )
        expect(scene.detailsToAddText == "动作、心理", "core scene details should use shared Chinese list text")

        let languageData = """
        {
          "originalExpression": "很好",
          "problem": "笼统",
          "betterWords": ["温暖", "坚定"],
          "betterSentence": "灯光很温暖",
          "whyBetter": "更具体"
        }
        """.data(using: .utf8)!
        let language = try JSONDecoder().decode(
            AIWritingReviewResult.LanguageUpgrade.self,
            from: languageData
        )
        expect(language.betterWordsText == "温暖、坚定", "language upgrade words should use shared Chinese list text")
    }

    private static func testWritingReviewJSONStorage() throws {
        let result = try JSONDecoder().decode(
            AIWritingReviewResult.self,
            from: writingReviewFixtureData()
        )

        let encoded = WritingReviewJSONStorage.encode(result)
        let decoded = WritingReviewJSONStorage.decode(encoded)
        let methodDecoded = WritingReviewJSONStorage.decode(result.encodedData())

        expect(decoded?.overallJudgement == "结构清楚", "storage should decode encoded writing review")
        expect(decoded?.scoreText == "55/60", "storage should preserve score formatting fields")
        expect(methodDecoded?.teacherComment == "继续保持", "result encodedData should round-trip through shared storage")
        expect(WritingReviewJSONStorage.decode(Data([0x7B])) == nil, "invalid storage data should fail softly")
    }

    private static func writingReviewFixtureData() -> Data {
        """
        {
          "overallJudgement": "结构清楚",
          "advancedTargetStandard": "扣题具体",
          "actualLevel": { "level": "B", "reason": "细节尚可" },
          "score": { "score": 55, "fullScore": 60 },
          "coreGap": "缺少关键场景",
          "possibleOCRIssues": [],
          "strengths": ["开头清楚"],
          "mainProblems": [],
          "ideaUpgrade": {},
          "contentAdvice": [],
          "structureAdvice": [],
          "languageUpgrade": [],
          "goodWordsAndSentences": {},
          "priorityRevisionPlan": ["补充动作"],
          "teacherComment": "继续保持"
        }
        """.data(using: .utf8)!
    }

    private static func testGoodWordsAndSentencesDecoding() throws {
        let data = """
        {
          "words": [
            { "word": "vivid", "meaning": "生动", "whereToUse": "描写", "example": "a vivid memory" }
          ],
          "phrases": [
            { "phrase": "light up", "whereToUse": "情绪变化", "example": "Her face lit up." }
          ],
          "sentences": [
            { "sentence": "I will never forget that day.", "whereToUse": "结尾", "whyUseful": "点题" }
          ],
          "sentencePatterns": [
            { "pattern": "Not only..., but also...", "usage": "递进", "example": "Not only did I learn, but I also grew." }
          ],
          "openingSentences": "开头一句",
          "transitionSentences": ["过渡一句"],
          "endingSentences": [],
          "stackingAdvice": "少量使用"
        }
        """.data(using: .utf8)!

        let value = try JSONDecoder().decode(
            AIWritingReviewResult.GoodWordsAndSentences.self,
            from: data
        )
        expect(value.words.first?.meaning == "生动", "good word should decode after model split")
        expect(value.phrases.first?.example == "Her face lit up.", "phrase should decode after model split")
        expect(value.sentences.first?.whyUseful == "点题", "sentence should decode after model split")
        expect(value.sentencePatterns.first?.usage == "递进", "sentence pattern should decode after model split")
        expect(value.openingSentences == ["开头一句"], "single opening sentence should normalize to array")
    }

    private static func testDiaryRequestConfiguration() throws {
        let doubao = AIRequestConfiguration.diary(model: .doubao)
        expect(doubao.thinking == "disabled", "doubao diary requests should not enable thinking")
        expect(doubao.maxOutputTokens == 2_048, "doubao diary token budget should preserve existing behavior")
        expect(doubao.modelName == "豆包日记", "doubao diary model name should use short title")

        let deepSeek = AIRequestConfiguration.diary(model: .deepSeek)
        expect(deepSeek.thinking == "enabled", "deepSeek diary requests should enable thinking")
        expect(deepSeek.maxOutputTokens == 4_096, "deepSeek diary token budget should preserve existing behavior")
        expect(deepSeek.modelName == "DeepSeek日记", "deepSeek diary model name should use short title")
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
        let writing = AIRequestConfiguration.deepSeek(
            modelName: "DeepSeek 写作命题",
            maxOutputTokens: 4_096
        )
        expect(writing.model == .deepSeek, "deepSeek helper should pin deepSeek model")
        expect(writing.usesDeepThinking, "deepSeek helper should enable thinking")

        let recognition = AIRequestConfiguration.doubao(
            modelName: "豆包作文识别",
            maxOutputTokens: 8_192
        )
        expect(recognition.model == .doubao, "doubao helper should pin doubao model")
        expect(!recognition.usesDeepThinking, "doubao helper should disable thinking")
    }
}
