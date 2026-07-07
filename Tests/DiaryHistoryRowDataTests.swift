import Foundation

@main
struct DiaryHistoryRowDataTests {
    static func main() {
        testRowDataReflectsEntryContentPresence()
        testWhitespaceOnlyContentIsTreatedAsEmpty()
        testEditableContentUsesSharedPresenceRules()
        testIndicatorsKeepStableOrderAndSystemImages()
        print("DiaryHistoryRowDataTests: 4 passed")
    }

    private static func testWhitespaceOnlyContentIsTreatedAsEmpty() {
        let entry = DiaryEntry(date: Date(timeIntervalSince1970: 0))
        entry.learned = " \n "
        entry.confused = "\t"
        entry.noted = ""
        entry.inspired = " 灵感 "

        let row = DiaryHistoryRowData(entry: entry)

        expect(!row.hasLearned, "whitespace-only learned text should be inactive")
        expect(!row.hasConfused, "whitespace-only confused text should be inactive")
        expect(!row.hasNoted, "empty note text should be inactive")
        expect(row.hasInspired, "trimmed non-empty inspired text should be active")
        expect(entry.hasAnyContent, "entry should have content when any trimmed section is non-empty")
        expect(entry.hasAIProcessableContent, "inspired text should count as AI-processable content")
    }

    private static func testEditableContentUsesSharedPresenceRules() {
        let blank = DiaryEntryEditableContent(
            learned: " ",
            confused: "\n",
            noted: "",
            inspired: "\t"
        )
        expect(!blank.hasInput, "editable content should ignore whitespace-only input")

        let content = DiaryEntryEditableContent(
            learned: "",
            confused: "卡住了",
            noted: "  ",
            inspired: ""
        )
        expect(content.hasInput, "editable content should detect trimmed non-empty input")
        expect(content.contentPresence.hasConfused, "editable content should expose shared presence flags")
        expect(content.contentPresence.hasAIProcessableContent, "confused content should be AI-processable")
    }

    private static func testRowDataReflectsEntryContentPresence() {
        let entry = DiaryEntry(date: Date(timeIntervalSince1970: 0))
        entry.learned = "函数图像"
        entry.confused = ""
        entry.noted = "明天复习"
        entry.inspired = ""

        let row = DiaryHistoryRowData(entry: entry)

        expect(row.id == entry.id, "row should keep entry id")
        expect(row.date == entry.date, "row should keep entry date")
        expect(row.hasLearned, "learned flag should be active when learned text exists")
        expect(!row.hasConfused, "confused flag should be inactive when confused text is empty")
        expect(row.hasNoted, "noted flag should be active when note text exists")
        expect(!row.hasInspired, "inspired flag should be inactive when inspired text is empty")
    }

    private static func testIndicatorsKeepStableOrderAndSystemImages() {
        let row = DiaryHistoryRowData(
            id: UUID(),
            date: Date(timeIntervalSince1970: 0),
            hasLearned: true,
            hasConfused: false,
            hasNoted: true,
            hasInspired: false
        )

        expect(
            row.indicators.map(\.kind) == [.learned, .confused, .noted, .inspired],
            "indicators should keep the row display order stable"
        )
        expect(
            row.indicators.map { $0.kind.systemImage } == [
                "book.fill",
                "questionmark.circle.fill",
                "note.text",
                "lightbulb.fill"
            ],
            "indicators should use SF Symbols"
        )
        expect(
            row.indicators.map(\.isActive) == [true, false, true, false],
            "indicators should mirror row activity flags"
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
