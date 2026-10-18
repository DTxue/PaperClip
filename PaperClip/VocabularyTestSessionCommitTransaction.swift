import Foundation
import SwiftData

enum VocabularyTestSessionCommitTransaction {
    @MainActor
    @discardableResult
    static func commitAndSave(
        deck: VocabularyDeck,
        batches: [VocabularyTestBatch],
        handwritingTestKind: VocabularyHandwritingTestKind,
        kind: String,
        testSelectionDescription: String?,
        startedAt: Date,
        modelContext: ModelContext,
        drawingData: (VocabularyTestBatch, Int) -> Data
    ) throws -> Bool {
        let didCommit = try VocabularyTestSessionCommitter.commit(
            deck: deck,
            batches: batches,
            handwritingTestKind: handwritingTestKind,
            kind: kind,
            testSelectionDescription: testSelectionDescription,
            startedAt: startedAt,
            modelContext: modelContext,
            drawingData: drawingData
        )
        guard didCommit else { return false }
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }
}
