import Foundation
import PencilKit

enum VocabularyTestDraftSnapshotBuilder {
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
}
