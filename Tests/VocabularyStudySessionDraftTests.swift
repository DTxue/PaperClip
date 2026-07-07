import Foundation

@main
enum VocabularyStudySessionDraftTests {
    static func main() {
        testEmptyDraftIsNotRecordable()
        testMakesSessionFromItems()
        print("VocabularyStudySessionDraftTests: 2 passed")
    }

    private static func testEmptyDraftIsNotRecordable() {
        let draft = VocabularyStudySessionDraft(
            deckID: UUID(),
            kind: "学习",
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 140),
            items: []
        )

        expect(!draft.isRecordable)
        expect(draft.makeSession() == nil)
    }

    private static func testMakesSessionFromItems() {
        let deckID = UUID()
        let cardID = UUID()
        let startedAt = Date(timeIntervalSince1970: 100)
        let endedAt = Date(timeIntervalSince1970: 160)
        let draft = VocabularyStudySessionDraft(
            deckID: deckID,
            kind: "闪卡",
            startedAt: startedAt,
            endedAt: endedAt,
            items: [
                VocabularyStudySessionItem(
                    cardID: cardID,
                    prompt: "meaning",
                    expectedAnswer: "term",
                    isCorrect: true
                )
            ]
        )

        let session = draft.makeSession()
        expect(session != nil)
        expect(session?.deckID == deckID)
        expect(session?.kind == "闪卡")
        expect(session?.startedAt == startedAt)
        expect(session?.endedAt == endedAt)
        expect(session?.duration == 60)
        expect(session?.totalCount == 1)
        expect(session?.correctCount == 1)
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
