import Foundation

@main
struct DiaryKnowledgeSnapshotTests {
    static func main() {
        testSnapshotGroupsDraftsConfirmedItemsAndAnalysisProgress()
        testKnowledgeExtractionUsesOnlyCurrentSources()
        print("DiaryKnowledgeSnapshotTests: 2 passed")
    }

    private static func testKnowledgeExtractionUsesOnlyCurrentSources() {
        let entry = DiaryEntry(date: .now)
        entry.inspired = "只有灵感的日记"
        entry.noted = "随手记录"
        expect(entry.hasAnyContent, "inspiration and notes remain ordinary diary content")
        expect(!entry.hasKnowledgeSourceContent, "retired inspiration analysis must not expose an empty knowledge action")

        entry.learned = "待整理的学习内容"
        expect(entry.hasKnowledgeSourceContent, "learned content still enables knowledge extraction")
        var edit = DiaryEntryEditableContent(entry: entry)
        edit.inspired = "修改灵感"
        edit.noted = "修改随手记"
        expect(edit.differs(from: entry), "ordinary edits remain saveable")
        expect(!edit.knowledgeContentDiffers(from: entry), "ordinary edits must not invalidate learned/confused knowledge")
        edit.confused = "新的困惑"
        expect(edit.knowledgeContentDiffers(from: entry), "changing a current extraction source still invalidates its analysis")
    }

    private static func testSnapshotGroupsDraftsConfirmedItemsAndAnalysisProgress() {
        let learnedLater = makeItem(source: "learned", status: "draft", createdAt: 30, summary: "later learned")
        learnedLater.aiAnalysisState = "done"
        let learnedEarlier = makeItem(source: "learned", status: "draft", createdAt: 10, summary: "earlier learned")
        learnedEarlier.aiAnalysisState = "none"
        let confused = makeItem(source: "confused", status: "draft", createdAt: 20, summary: "confused")
        confused.aiAnalysisState = "done"
        let emptySummaryDraft = makeItem(source: "learned", status: "draft", createdAt: 15, summary: "")
        let confirmed = makeItem(source: "learned", status: "confirmed", createdAt: 5, summary: "confirmed")
        let ignored = makeItem(source: "learned", status: "archived", createdAt: 1, summary: "ignored")

        let snapshot = DiaryKnowledgeSnapshot(items: [
            learnedLater,
            learnedEarlier,
            confused,
            emptySummaryDraft,
            confirmed,
            ignored
        ])

        expect(snapshot.hasDrafts, "draft status items should mark snapshot as having drafts")
        expect(snapshot.learnedDrafts.map(\.summary) == ["earlier learned", "", "later learned"], "learned drafts should be oldest first")
        expect(snapshot.confusedDrafts.map(\.summary) == ["confused"], "confused drafts should include confused source only")
        expect(snapshot.confirmedItems.map(\.summary) == ["confirmed"], "confirmed items should be grouped separately")
        expect(snapshot.draftAnalysisTotal == 3, "non-empty draft summaries should count toward analysis total")
        expect(snapshot.draftAnalysisDone == 2, "done non-empty draft summaries should count toward analysis progress")
    }

    private static func makeItem(
        source: String,
        status: String,
        createdAt: TimeInterval,
        summary: String
    ) -> KnowledgeItem {
        let entry = DiaryEntry(date: Date(timeIntervalSince1970: 0))
        let item = KnowledgeItem(summary: summary, source: source, entry: entry)
        item.status = status
        item.createdAt = Date(timeIntervalSince1970: createdAt)
        return item
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
