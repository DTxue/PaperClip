import Foundation
import PencilKit

struct WritingDrawingDataCache {
    private var revision = -1
    private var data = Data()

    @MainActor
    mutating func data(for drawingStore: WritingDrawingStore) -> Data {
        guard revision != drawingStore.revision else { return data }
        revision = drawingStore.revision
        data = DrawingDataSupport.data(from: drawingStore.drawing)
        return data
    }
}

extension WritingWorkspaceView {
    func draftSavePayload() -> WritingDraftSavePayload {
        let nextPaperStyle = prompt.language == .english ? WritingPaperStyle.lined : paperStyle
        return WritingDraftSavePayload(
            paperStyle: nextPaperStyle,
            blackPaperMode: blackPaperMode,
            paperSize: paperSize,
            rulingSpacing: rulingSpacing,
            reviewStatus: normalizedDraftReviewStatus(),
            drawingData: encodedDrawingData(),
            hasInk: DrawingDataSupport.hasInk(drawingStore.drawing)
        )
    }

    func encodedDrawingData() -> Data {
        drawingDataCache.data(for: drawingStore)
    }

    func shouldCreateDraft(_ payload: WritingDraftSavePayload) -> Bool {
        payload.shouldCreateDraft
    }

    func persistDraftChanges(rollbackActiveDraft: Bool) -> Bool {
        do {
            try modelContext.saveOrRollbackIfNeeded()
            return true
        } catch {
            if rollbackActiveDraft {
                activeDraft = nil
            }
            alert = AppAlert(title: "无法保存作文草稿", error: error)
            return false
        }
    }

    private func normalizedDraftReviewStatus() -> WritingReviewStatus {
        activeDraft?.reviewStatus == .failed ? .draft : (activeDraft?.reviewStatus ?? .draft)
    }
}
