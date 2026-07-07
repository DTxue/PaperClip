import Foundation

@main
struct VocabularyTextImporterTests {
    static func main() {
        testTab()
        testPipeWithFields()
        testEquals()
        testColon()
        testDashDoesNotSplitHyphenatedWord()
        testPairedLines()
        testCSVQuotes()
        testMarkdown()
        testJSON()
        testInvalidRows()
        testInvalidExplicitSeparators()
        testPairedLinesKeepsOddTrailingLine()
        testImportSummary()
        print("VocabularyTextImporterTests: 13 passed")
    }

    private static func testTab() {
        let result = VocabularyTextImporter.parse("apple\t苹果\nbook\t书")
        expect(result.format == .tab)
        expect(result.rows.map(\.term) == ["apple", "book"])
        expect(result.rows.map(\.definition) == ["苹果", "书"])
    }

    private static func testPipeWithFields() {
        let result = VocabularyTextImporter.parse(
            "apple | 苹果 | /ˈæpəl/ | I ate an apple. | noun",
            format: .pipe
        )
        expect(result.rows[0].phonetic == "/ˈæpəl/")
        expect(result.rows[0].example == "I ate an apple.")
        expect(result.rows[0].partOfSpeech == "noun")
    }

    private static func testEquals() {
        let result = VocabularyTextImporter.parse("apple = 苹果\nbook = 书")
        expect(result.format == .equals)
        expect(result.rows.allSatisfy(\.isValid))
    }

    private static func testColon() {
        let result = VocabularyTextImporter.parse("apple: 苹果\nbook：书")
        expect(result.format == .colon)
        expect(result.rows.count == 2)
        expect(result.rows.allSatisfy(\.isValid))
    }

    private static func testDashDoesNotSplitHyphenatedWord() {
        let result = VocabularyTextImporter.parse("well-known - 著名的", format: .dash)
        expect(result.rows[0].term == "well-known")
        expect(result.rows[0].definition == "著名的")
    }

    private static func testPairedLines() {
        let result = VocabularyTextImporter.parse("apple\n苹果\n\nbook\n书")
        expect(result.format == .pairedLines)
        expect(result.rows.count == 2)
        expect(result.rows[1].term == "book")
    }

    private static func testCSVQuotes() {
        let result = VocabularyTextImporter.parse("\"take off\",\"起飞,脱下\"\nbook,书", format: .comma)
        expect(result.rows[0].term == "take off")
        expect(result.rows[0].definition == "起飞,脱下")
    }

    private static func testMarkdown() {
        let text = """
        | term | definition |
        | --- | --- |
        | apple | 苹果 |
        """
        let result = VocabularyTextImporter.parse(text)
        expect(result.format == .markdown)
        expect(result.rows.count == 1)
        expect(result.rows[0].term == "apple")
    }

    private static func testJSON() {
        let result = VocabularyTextImporter.parse(
            #"[{"term":"apple","definition":"苹果","example":"An apple."}]"#
        )
        expect(result.format == .json)
        expect(result.rows[0].example == "An apple.")
    }

    private static func testInvalidRows() {
        let result = VocabularyTextImporter.parse("apple\t\n\t书", format: .tab)
        expect(result.rows.filter { !$0.isValid }.count == 2)
    }

    private static func testInvalidExplicitSeparators() {
        let colon = VocabularyTextImporter.parse("apple 苹果", format: .colon)
        let dash = VocabularyTextImporter.parse("well-known word", format: .dash)

        expect(!colon.rows[0].isValid)
        expect(colon.rows[0].error == "未找到冒号分隔符")
        expect(!dash.rows[0].isValid)
        expect(dash.rows[0].error == "未找到两侧带空格的横线分隔符")
    }

    private static func testPairedLinesKeepsOddTrailingLine() {
        let result = VocabularyTextImporter.parse("apple\n苹果\norphan", format: .pairedLines)

        expect(result.rows.count == 2)
        expect(result.rows[0].term == "apple")
        expect(result.rows[1].term == "orphan")
        expect(!result.rows[1].isValid)
    }

    private static func testImportSummary() {
        let result = VocabularyTextImporter.parse("apple\t苹果\nbook\t\ncat\t猫", format: .tab)
        let summary = result.summary
        let projection = result.projection

        expect(summary.totalCount == 3)
        expect(summary.validCount == 2)
        expect(summary.failedCount == 1)
        expect(projection.validRows.map(\.term) == ["apple", "cat"])
        expect(projection.summary == summary)
        expect(summary.hasValidRows)
        expect(summary.createConfirmTitle() == "创建并导入 2 项")
        expect(summary.importConfirmTitle() == "导入 2 项")
        expect(summary.canCreateDeck(title: "  四级词汇  "))
        expect(!summary.canCreateDeck(title: "   "))
        expect(VocabularyImportSummary(totalCount: 1, validCount: 2).failedCount == 0)
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
