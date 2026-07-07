import Foundation

@main
struct PaperChoiceParserTests {
    static func main() {
        assertEqual(
            PaperChoiceParser.isMultipleChoice(questionText: "本题为多选题", correctAnswer: "A"),
            true,
            "keyword marks multiple-choice questions"
        )

        assertEqual(
            PaperChoiceParser.isMultipleChoice(questionText: "", correctAnswer: "正确答案：A、C"),
            true,
            "answer prefixes and separators are ignored"
        )

        assertEqual(
            PaperChoiceParser.isMultipleChoice(questionText: "", correctAnswer: "答案：A 解析略"),
            false,
            "non-label answer text is not treated as multiple-choice"
        )

        assertEqual(
            PaperChoiceParser.optionLabels(in: "（Ａ）一\n（Ｂ）二\n（Ｃ）三", questionType: .choice),
            ["A", "B", "C"],
            "full-width option labels are normalized"
        )

        assertEqual(
            PaperChoiceParser.optionLabels(in: "", questionType: .choice),
            ["A", "B", "C", "D"],
            "choice questions default to A-D when OCR text is empty"
        )

        assertEqual(
            PaperChoiceParser.optionLabels(in: "", questionType: .calculation),
            [],
            "non-choice questions do not get default options"
        )

        print("PaperChoiceParserTests: 6 passed")
    }

    static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if actual != expected {
            fatalError("\(message): expected \(expected), got \(actual)", file: file, line: line)
        }
    }
}
