import Foundation
import SwiftData

enum VocabularyStudySessionTransaction {
    @MainActor
    @discardableResult
    static func recordSession(
        deckID: UUID,
        kind: String,
        startedAt: Date,
        items: [VocabularyStudySessionItem],
        in modelContext: ModelContext
    ) throws -> Bool {
        guard let session = VocabularyStudySessionDraft(
            deckID: deckID,
            kind: kind,
            startedAt: startedAt,
            items: items
        ).makeSession() else { return false }

        modelContext.insert(session)
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }

}
