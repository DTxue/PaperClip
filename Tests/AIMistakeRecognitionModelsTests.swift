import Foundation

@main
enum AIMistakeRecognitionModelsTests {
    static func main() throws {
        let decoded = try JSONDecoder().decode(
            AIMistakeRecognitionResult.self,
            from: Data(#"{"questionText":"1 + 1 = ?","subject":"数学","grade":"七年级","knowledgePoints":["有理数加法","基础运算"]}"#.utf8)
        )
        expect(decoded.questionText == "1 + 1 = ?", "decodes recognized question text")
        expect(decoded.subject == "数学", "decodes recognized subject")
        expect(decoded.grade == "七年级", "decodes recognized grade")
        expect(decoded.knowledgePoints == ["有理数加法", "基础运算"], "decodes knowledge points")
        expect(MistakeRecognitionPrompt.instruction.contains("不要解题"), "prompt forbids solving")
        expect(MistakeRecognitionPrompt.instruction.contains("按图片顺序"), "prompt preserves image order")
        expect(MistakeRecognitionPrompt.instruction.contains("行内公式必须放在 $...$"), "prompt emits renderable formula delimiters")
        expect(MistakeRecognitionPrompt.instruction.contains("学科"), "prompt requests subject classification")
        expect(MistakeRecognitionPrompt.instruction.contains("知识点"), "prompt requests knowledge points")
        expect(MistakeRecognitionPrompt.instruction.contains("年级"), "prompt requests grade classification")
        expect(MistakeRecognitionPrompt.instruction.contains("只输出合法 JSON"), "prompt requires structured output")

        let merged = MistakeRecognitionAutofill.mergedKnowledgePoints(
            existing: "基础运算，易错",
            recognized: ["有理数加法", "基础运算", " "]
        )
        expect(merged == "基础运算,易错,有理数加法", "merges knowledge points without overwriting or duplicates")
        expect(
            MistakeRecognitionAutofill.shouldApplyRecognizedValue(
                current: "数学",
                requestStart: "数学"
            ),
            "applies recognition when a field has not changed during the request"
        )
        expect(
            !MistakeRecognitionAutofill.shouldApplyRecognizedValue(
                current: "物理",
                requestStart: "数学"
            ),
            "preserves a field edited while recognition is running"
        )

        print("AIMistakeRecognitionModelsTests: 14 passed")
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
