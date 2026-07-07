import Foundation

@main
struct AIServiceResponseDecodingTests {
    static func main() {
        testSanitizedJSONValueRemovesFenceAndText()
        testSanitizedJSONValueEscapesInvalidBackslashes()
        testValidEscapesArePreserved()
        testDecodedJSONValueUsesSanitizedContentAndSnakeCaseKeys()
        print("AIServiceResponseDecodingTests: 4 passed")
    }

    private static func testSanitizedJSONValueRemovesFenceAndText() {
        let content = """
        下面是结果：
        ```json
        [{"text":"函数","change":"新增"}]
        ```
        请查收
        """

        expect(
            AIResponseDecodingSupport.sanitizedJSONValue(from: content) == #"[{"text":"函数","change":"新增"}]"#,
            "sanitized JSON should strip prose and code fences"
        )
    }

    private static func testSanitizedJSONValueEscapesInvalidBackslashes() {
        let content = #"{"formula":"a \cdot x"}"#

        expect(
            AIResponseDecodingSupport.sanitizedJSONValue(from: content) == #"{"formula":"a \\cdot x"}"#,
            "invalid JSON backslashes should be escaped"
        )
    }

    private static func testValidEscapesArePreserved() {
        let content = #"{"line":"第一行\n第二行","quote":"\""}"#

        expect(
            AIResponseDecodingSupport.sanitizedJSONValue(from: content) == content,
            "valid JSON escapes should be preserved"
        )
    }

    private static func testDecodedJSONValueUsesSanitizedContentAndSnakeCaseKeys() {
        struct Item: Decodable {
            let displayTitle: String
        }

        let content = """
        ```json
        {"display_title":"函数"}
        ```
        """

        let value = try! AIResponseDecodingSupport.decodedJSONValue(Item.self, from: content)
        expect(
            value.displayTitle == "函数",
            "AI decoding should sanitize content and use snake-case keys"
        )
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
