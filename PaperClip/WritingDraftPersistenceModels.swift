import CoreGraphics
import Foundation

struct WritingDraftSavePayload {
    let paperStyle: WritingPaperStyle
    let blackPaperMode: Bool
    let paperSize: CGSize
    let rulingSpacing: Double
    let reviewStatus: WritingReviewStatus
    let drawingData: Data
    let hasInk: Bool

    var shouldCreateDraft: Bool {
        hasInk
            || paperStyle != .lined
            || blackPaperMode
            || !WritingPaperMetrics.isClose(paperSize, to: WritingPaperMetrics.defaultSize)
            || !WritingPaperMetrics.isClose(
                rulingSpacing,
                to: WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
            )
    }
}

extension WritingDraft {
    func apply(_ payload: WritingDraftSavePayload) -> Bool {
        let hasChanges = drawingData != payload.drawingData
            || paperStyle != payload.paperStyle
            || blackPaperMode != payload.blackPaperMode
            || !WritingPaperMetrics.isClose(paperSize, to: payload.paperSize)
            || !WritingPaperMetrics.isClose(paperRulingSpacing, to: payload.rulingSpacing)
            || reviewStatus != payload.reviewStatus

        guard hasChanges else { return false }

        drawingData = payload.drawingData
        paperStyle = payload.paperStyle
        blackPaperMode = payload.blackPaperMode
        paperSize = payload.paperSize
        paperRulingSpacing = payload.rulingSpacing
        updatedAt = .now
        reviewStatus = payload.reviewStatus
        return true
    }
}
