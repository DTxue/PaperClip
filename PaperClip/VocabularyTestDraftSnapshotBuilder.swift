import Foundation
import PencilKit

enum VocabularyTestDraftSnapshotBuilder {
    static func batchSnapshots(
        from batches: [VocabularyTestBatch],
        drawingDataCache: VocabularyDraftDrawingDataCache
    ) -> [VocabularyTestDraftBatchSnapshot] {
        batches.map { batch in
            VocabularyTestDraftBatchSnapshot(
                id: batch.id,
                startIndex: batch.startIndex,
                cardIDs: batch.cards.map(\.id),
                drawingsData: encodedDrawings(for: batch, drawingDataCache: drawingDataCache),
                status: batch.status.rawValue,
                gradingAttempts: batch.gradingAttempts,
                result: batch.result,
                errorMessage: batch.errorMessage
            )
        }
    }

    static func encodedDrawingData(
        for batch: VocabularyTestBatch,
        drawingIndex: Int,
        drawingDataCache: VocabularyDraftDrawingDataCache
    ) -> Data {
        let key = VocabularyDraftDrawingKey(batchID: batch.id, drawingIndex: drawingIndex)
        guard batch.drawings.indices.contains(drawingIndex) else {
            return DrawingDataSupport.emptyData()
        }
        return drawingDataCache.data(for: key, drawing: batch.drawings[drawingIndex])
    }

    private static func encodedDrawings(
        for batch: VocabularyTestBatch,
        drawingDataCache: VocabularyDraftDrawingDataCache
    ) -> [Data] {
        batch.drawings.indices.map { index in
            encodedDrawingData(
                for: batch,
                drawingIndex: index,
                drawingDataCache: drawingDataCache
            )
        }
    }
}
