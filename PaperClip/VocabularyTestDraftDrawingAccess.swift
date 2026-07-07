import Foundation

extension VocabularyTestView {
    func currentDrawingDataForDraft() -> Data {
        DrawingDataSupport.data(from: currentDrawing)
    }

    func encodedDrawingData(for batch: VocabularyTestBatch, drawingIndex: Int) -> Data {
        VocabularyTestDraftSnapshotBuilder.encodedDrawingData(
            for: batch,
            drawingIndex: drawingIndex,
            drawingDataCache: draftDrawingDataCache
        )
    }
}
