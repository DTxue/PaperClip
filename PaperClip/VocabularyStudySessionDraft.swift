import Foundation

struct VocabularyStudySessionDraft {
    let deckID: UUID
    let kind: String
    let startedAt: Date
    let endedAt: Date
    let items: [VocabularyStudySessionItem]
    let testSelectionDescription: String?

    init(
        deckID: UUID,
        kind: String,
        startedAt: Date,
        endedAt: Date = .now,
        items: [VocabularyStudySessionItem],
        testSelectionDescription: String? = nil
    ) {
        self.deckID = deckID
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.items = items
        self.testSelectionDescription = testSelectionDescription
    }

    var isRecordable: Bool {
        !items.isEmpty
    }

    func makeSession() -> VocabularyStudySession? {
        guard isRecordable else { return nil }
        return VocabularyStudySession(
            deckID: deckID,
            kind: kind,
            startedAt: startedAt,
            endedAt: endedAt,
            items: items,
            testSelectionDescription: testSelectionDescription
        )
    }
}
