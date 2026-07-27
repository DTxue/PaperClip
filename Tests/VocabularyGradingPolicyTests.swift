import Foundation

@main
enum VocabularyGradingPolicyTests {
    static func main() throws {
        try testBlankAnswersCannotBeMarkedCorrect()
        try testAnsweredItemsKeepTheAIResult()
        testMissingAIItemsAreErrors()

        print("VocabularyGradingPolicyTests: 12 passed")
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
            hasVisibleAnswers: [false, false]
        )

        expect(result.items.map(\.index) == [1, 2])
        expect(result.items.allSatisfy { !$0.isCorrect })
        expect(result.items.allSatisfy { $0.comment == "未作答" })
        expect(result.items.allSatisfy { $0.recognizedText.isEmpty })
    }

    private static func testAnsweredItemsKeepTheAIResult() throws {
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
            hasVisibleAnswers: [true, false]
        )

        expect(result.items.count == 2)
        expect(result.items[0].isCorrect)
        expect(result.items[0].recognizedText == "pen")
        expect(!result.items[1].isCorrect)
        expect(result.items[1].comment == "未作答")
    }

    private static func testMissingAIItemsAreErrors() {
        let result = VocabularyGradingPolicy.validated(
            VocabularyGradingResult(items: []),
            hasVisibleAnswers: [true]
        )

        expect(result.items.count == 1)
        expect(!result.items[0].isCorrect)
        expect(result.items[0].comment == "批改结果缺失")
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
