import Foundation

@main
enum AIExamGradingPromptTests {
    static func main() {
        let instructions = AIExamGradingPrompt.instructions(pageCount: 1)

        expect(
            instructions.contains("每道已作答题目必须恰好返回一个 item"),
            "requires one grading item for every answered question"
        )
        expect(
            instructions.contains("\"questionNumber\":\"49\"")
                && instructions.contains("\"questionNumber\":\"50\""),
            "uses a multi-question response example"
        )
        expect(
            instructions.contains("不得返回百分比或图片像素坐标"),
            "forbids percentage and pixel stamp coordinates"
        )
        expect(
            instructions.contains("\"x\":0.391,\"y\":888")
                && instructions.contains("\"x\":0.391,\"y\":0.888")
                && instructions.contains("不得让 x/y 使用不同坐标尺度"),
            "shows the model how to correct mixed normalized and 0...1000 axes"
        )

        print("AIExamGradingPromptTests: 4 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
