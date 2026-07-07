import Foundation

extension WritingWorkspaceView {
    func resetPaperMetrics() {
        paperWidth = WritingPaperMetrics.defaultWidth
        paperHeight = WritingPaperMetrics.defaultHeight
        rulingSpacing = WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
        scheduleAutosave()
    }
}
