import Foundation

@main
struct AIServiceResponseDecodingTests {
    static func main() {
        testSanitizedJSONValueRemovesFenceAndText()
        testSanitizedJSONValueEscapesInvalidBackslashes()
        testValidEscapesArePreserved()
        testDecodedJSONValueUsesSanitizedContentAndSnakeCaseKeys()
        testVocabularyEnglishDefinitionsDecodeTopLevelArray()
        testVocabularyEnglishDefinitionsDecodeItemsObject()
        print("AIServiceResponseDecodingTests: 6 passed")
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

    private static func testVocabularyEnglishDefinitionsDecodeTopLevelArray() {
        let content = """
        [{"index":1,"englishDefinition":"the feeling of being friends"},{"index":2,"englishDefinition":"always telling the truth and being fair"}]
        """

        let value = try! AIResponseDecodingSupport.decodedJSONValue(
            VocabularyEnglishDefinitionGenerationResult.self,
            from: content
        )
        expect(
            value.items.map(\.englishDefinition) == [
                "the feeling of being friends",
                "always telling the truth and being fair"
            ],
            "English definition generation should accept top-level array responses"
        )
    }

    private static func testVocabularyEnglishDefinitionsDecodeItemsObject() {
        let content = """
        {"items":[{"index":1,"englishDefinition":"to use something and give it back later"}]}
        """

        let value = try! AIResponseDecodingSupport.decodedJSONValue(
            VocabularyEnglishDefinitionGenerationResult.self,
            from: content
        )
        expect(
            value.items.first?.englishDefinition == "to use something and give it back later",
            "English definition generation should still accept the prompted items object"
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
