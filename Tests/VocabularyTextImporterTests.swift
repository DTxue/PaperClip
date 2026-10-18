import Foundation

@main
struct VocabularyTextImporterTests {
    static func main() {
        testTab()
        testTabWithFields()
        testPairedLines()
        testCSVQuotes()
        testInvalidRows()
        testPairedLinesKeepsOddTrailingLine()
        testImportSummary()
        print("VocabularyTextImporterTests: 7 passed")
    }

    private static func testTab() {
        let result = VocabularyTextImporter.parse("apple\t苹果\nbook\t书", format: .tab)
        expect(result.format == .tab)
        expect(result.rows.map(\.term) == ["apple", "book"])
        expect(result.rows.map(\.definition) == ["苹果", "书"])
    }

    private static func testTabWithFields() {
        let result = VocabularyTextImporter.parse(
            "apple\t苹果\t/ˈæpəl/\tI ate an apple.\tnoun",
            format: .tab
        )
        expect(result.rows[0].phonetic == "/ˈæpəl/")
        expect(result.rows[0].example == "I ate an apple.")
        expect(result.rows[0].partOfSpeech == "noun")
    }

    private static func testPairedLines() {
        let result = VocabularyTextImporter.parse("apple\n苹果\n\nbook\n书", format: .pairedLines)
        expect(result.format == .pairedLines)
        expect(result.rows.count == 2)
        expect(result.rows[1].term == "book")
    }

    private static func testCSVQuotes() {
        let result = VocabularyTextImporter.parse("\"take off\",\"起飞,脱下\"\nbook,书", format: .comma)
        expect(result.rows[0].term == "take off")
        expect(result.rows[0].definition == "起飞,脱下")
    }

    private static func testInvalidRows() {
        let result = VocabularyTextImporter.parse("apple\t\n\t书", format: .tab)
        expect(result.rows.filter { !$0.isValid }.count == 2)
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
