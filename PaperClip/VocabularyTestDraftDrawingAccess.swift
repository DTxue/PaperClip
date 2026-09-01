import Foundation

extension VocabularyTestView {
    func encodedDrawingData(for batch: VocabularyTestBatch, drawingIndex: Int) -> Data {
        VocabularyTestDraftSnapshotBuilder.encodedDrawingData(
            for: batch,
            drawingIndex: drawingIndex,
            drawingDataCache: draftDrawingDataCache
        )
    }
}
