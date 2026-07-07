import Foundation

@main
struct HomeKnowledgeSnapshotTests {
    static func main() {
        testKnowledgeRowDataMapsModelFields()
        testKnowledgeRowPropertiesIncludeDisplayAndQueryFields()
        testSubjectsUseCanonicalOrderWithUnknownsAtEnd()
        testCompositeSubjectFiltering()
        testWhitespaceSelectedSubjectIsTreatedAsAll()
        print("HomeKnowledgeSnapshotTests: 5 passed")
    }

    private static func testKnowledgeRowDataMapsModelFields() {
        let entry = DiaryEntry(date: Date(timeIntervalSince1970: 0))
        let item = KnowledgeItem(summary: "二次函数顶点式", source: "learned", entry: entry)
        item.subject = "数学·函数"
        item.diaryDate = Date(timeIntervalSince1970: 86_400)

        let row = KnowledgeItemListRowData(item: item)

        expect(row.id == item.id, "row should keep item id")
        expect(row.summary == "二次函数顶点式", "row should keep summary")
        expect(row.subject == "数学·函数", "row should keep subject")
        expect(row.diaryDate == item.diaryDate, "row should keep diary date")
    }

    private static func testKnowledgeRowPropertiesIncludeDisplayAndQueryFields() {
        expect(
            KnowledgeItemListRowData.propertiesToFetch.count == 6,
            "knowledge row fetch properties should include display fields plus predicate and sort fields"
        )
    }

    private static func testSubjectsUseCanonicalOrderWithUnknownsAtEnd() {
        let items = [
            makeItem(subject: "物理·力学"),
            makeItem(subject: "数学·函数"),
            makeItem(subject: "自定义"),
            makeItem(subject: "英语·阅读"),
            makeItem(subject: "天文")
        ]

        let snapshot = HomeKnowledgeSnapshot(items: items, selectedSubject: "")

        expect(snapshot.subjects == ["数学", "英语", "物理", "天文", "自定义"], "subjects should use canonical order before unknown categories")
    }

    private static func testCompositeSubjectFiltering() {
        let mathItem = makeItem(subject: "数学·函数")
        let physicsItem = makeItem(subject: "物理·力学")
        let snapshot = HomeKnowledgeSnapshot(items: [mathItem, physicsItem], selectedSubject: "数学")

        expect(snapshot.visibleItems.map(\.id) == [mathItem.id], "subject filter should match composite subjects")
    }

    private static func testWhitespaceSelectedSubjectIsTreatedAsAll() {
        let items = [makeItem(subject: "数学"), makeItem(subject: "英语")]
        let snapshot = HomeKnowledgeSnapshot(items: items, selectedSubject: "   ")

        expect(snapshot.visibleItems.map(\.id) == items.map(\.id), "whitespace subject filter should not hide items")
    }

    private static func makeItem(subject: String) -> KnowledgeItemListRowData {
        let entry = DiaryEntry(date: Date(timeIntervalSince1970: 0))
        let item = KnowledgeItem(summary: subject, source: "learned", entry: entry)
        item.subject = subject
        item.status = "confirmed"
        return KnowledgeItemListRowData(item: item)
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
