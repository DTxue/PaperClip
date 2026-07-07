import Foundation
import SwiftData

enum VocabularyTestSessionCommitTransaction {
    @MainActor
    @discardableResult
    static func commitAndSave(
        deck: VocabularyDeck,
        batches: [VocabularyTestBatch],
        kind: String,
        startedAt: Date,
        modelContext: ModelContext,
        drawingData: (VocabularyTestBatch, Int) -> Data
    ) throws -> Bool {
        let didCommit = try VocabularyTestSessionCommitter.commit(
            deck: deck,
            batches: batches,
            kind: kind,
            startedAt: startedAt,
            modelContext: modelContext,
            drawingData: drawingData
        )
        guard didCommit else { return false }
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }
}
