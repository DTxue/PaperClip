import Foundation

@main
enum VocabularyGradingPolicyTests {
    static func main() throws {
        try testBlankAnswersCannotBeMarkedCorrect()
        try testRecognizedAnswerDeterminesCorrectness()
        try testRecognizedSpellingErrorOverridesContradictoryAIResult()
        try testEnglishDefinitionUsesOnlyAllowedNormalization()
        try testEnglishDefinitionRejectsOtherDifferences()
        testMissingAIItemsAreErrors()

        print("VocabularyGradingPolicyTests: all passed")
    }

    private static func testBlankAnswersCannotBeMarkedCorrect() throws {
        let aiResult = try JSONDecoder().decode(
            VocabularyGradingResult.self,
            from: Data(
                """
                {
                  "items": [
                    {
                      "index": 1,
                      "isCorrect": true,
                      "comment": "正确",
                      "recognizedText": ""
                    },
                    {
                      "index": 2,
                      "isCorrect": true,
                      "comment": "正确",
                      "recognizedText": ""
                    }
                  ]
                }
                """.utf8
            )
        )

        let result = VocabularyGradingPolicy.validated(
            aiResult,
            expectedAnswers: ["pen", "book"],
            hasVisibleAnswers: [false, false]
        )

        expect(result.items.map(\.index) == [1, 2])
        expect(result.items.allSatisfy { !$0.isCorrect })
        expect(result.items.allSatisfy { $0.comment == "未作答" })
        expect(result.items.allSatisfy { $0.recognizedText.isEmpty })
    }

    private static func testRecognizedAnswerDeterminesCorrectness() throws {
        let aiResult = try JSONDecoder().decode(
            VocabularyGradingResult.self,
            from: Data(
                """
                {
                  "items": [
                    {
                      "index": 1,
                      "isCorrect": true,
                      "comment": "正确",
                      "recognizedText": "pen"
                    },
                    {
                      "index": 2,
                      "isCorrect": true,
                      "comment": "正确",
                      "recognizedText": ""
                    }
                  ]
                }
                """.utf8
            )
        )

        let result = VocabularyGradingPolicy.validated(
            aiResult,
            expectedAnswers: ["pen", "book"],
            hasVisibleAnswers: [true, false]
        )

        expect(result.items.count == 2)
        expect(result.items[0].isCorrect)
        expect(result.items[0].recognizedText == "pen")
        expect(!result.items[1].isCorrect)
        expect(result.items[1].comment == "未作答")
    }

    private static func testRecognizedSpellingErrorOverridesContradictoryAIResult() throws {
        let aiResult = try JSONDecoder().decode(
            VocabularyGradingResult.self,
            from: Data(
                """
                {
                  "items": [
                    {
                      "index": 1,
                      "isCorrect": true,
                      "comment": "答案应为 lie，此处拼写错误",
                      "recognizedText": "lier"
                    }
                  ]
                }
                """.utf8
            )
        )

        let result = VocabularyGradingPolicy.validated(
            aiResult,
            expectedAnswers: ["lie"],
            hasVisibleAnswers: [true]
        )

        expect(result.items.count == 1)
        expect(!result.items[0].isCorrect)
        expect(result.items[0].recognizedText == "lier")
        expect(result.items[0].comment.contains("lie"))
    }

    private static func testEnglishDefinitionUsesOnlyAllowedNormalization() throws {
        let aiResult = try gradingResult(
            recognizedText: "  TO   PAUSE before acting!!!  ",
            aiIsCorrect: false
        )

        let result = VocabularyGradingPolicy.validated(
            aiResult,
            expectedAnswers: ["to pause before acting"],
            hasVisibleAnswers: [true],
            matchPolicy: .englishDefinition
        )

        expect(result.items[0].isCorrect)
        expect(result.items[0].comment == "正确")
    }

    private static func testEnglishDefinitionRejectsOtherDifferences() throws {
        let accented = VocabularyGradingPolicy.validated(
            try gradingResult(recognizedText: "resume", aiIsCorrect: true),
            expectedAnswers: ["résumé"],
            hasVisibleAnswers: [true],
            matchPolicy: .englishDefinition
        )
        let internalPunctuation = VocabularyGradingPolicy.validated(
            try gradingResult(
                recognizedText: "to pause before acting",
                aiIsCorrect: true
            ),
            expectedAnswers: ["to pause, before acting"],
            hasVisibleAnswers: [true],
            matchPolicy: .englishDefinition
        )
        let aiSuggestedAcceptance = VocabularyGradingPolicy.validated(
            VocabularyGradingResult(items: [
                VocabularyGradingItem(
                    index: 1,
                    isCorrect: true,
                    comment: "意思相近，可以接受",
                    recognizedText: "to wait before acting"
                )
            ]),
            expectedAnswers: ["to pause before acting"],
            hasVisibleAnswers: [true],
            matchPolicy: .englishDefinition
        )

        expect(!accented.items[0].isCorrect)
        expect(!internalPunctuation.items[0].isCorrect)
        expect(!aiSuggestedAcceptance.items[0].isCorrect)
        expect(aiSuggestedAcceptance.items[0].comment == "答案应为 to pause before acting")
    }

    private static func testMissingAIItemsAreErrors() {
        let result = VocabularyGradingPolicy.validated(
            VocabularyGradingResult(items: []),
            expectedAnswers: ["pen"],
            hasVisibleAnswers: [true]
        )

        expect(result.items.count == 1)
        expect(!result.items[0].isCorrect)
        expect(result.items[0].comment == "批改结果缺失")
    }

    private static func gradingResult(
        recognizedText: String,
        aiIsCorrect: Bool
    ) throws -> VocabularyGradingResult {
        try JSONDecoder().decode(
            VocabularyGradingResult.self,
            from: Data(
                """
                {
                  "items": [
                    {
                      "index": 1,
                      "isCorrect": \(aiIsCorrect),
                      "comment": "",
                      "recognizedText": "\(recognizedText)"
                    }
                  ]
                }
                """.utf8
            )
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
