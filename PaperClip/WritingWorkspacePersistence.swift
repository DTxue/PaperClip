import SwiftUI
import SwiftData
import PencilKit

extension WritingWorkspaceView {
    func loadDraftIfNeeded() {
        guard !hasLoadedDraft else { return }
        hasLoadedDraft = true
        isRestoringDraft = true
        defer { isRestoringDraft = false }

        guard let existing = fetchLatestDraft() else {
            activeDraft = nil
            drawingStore.drawing = PKDrawing()
            drawingRevision &+= 1
            paperStyle = .lined
            blackPaperMode = false
            paperWidth = WritingPaperMetrics.defaultWidth
            paperHeight = WritingPaperMetrics.defaultHeight
            rulingSpacing = WritingPaperMetrics.defaultRulingSpacing(for: .lined)
            return
        }

        activeDraft = existing
        drawingStore.drawing = DrawingDataSupport.drawingOrEmpty(from: existing.drawingData)
        drawingRevision &+= 1
        paperStyle = prompt.language == .english ? .lined : existing.paperStyle
        blackPaperMode = existing.blackPaperMode
        paperWidth = Double(existing.paperSize.width)
        paperHeight = Double(existing.paperSize.height)
        let loadedSpacing = existing.paperRulingSpacing
        let legacySpacing = WritingPaperMetrics.legacyRulingSpacing(for: paperStyle)
        rulingSpacing = loadedSpacing == legacySpacing
            ? WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
            : loadedSpacing
    }

    func fetchLatestDraft() -> WritingDraft? {
        do {
            return try modelContext.fetchLatestWritingDraft(promptID: prompt.id)
        } catch {
            alert = AppAlert(title: "无法读取作文草稿", error: error)
            return nil
        }
    }

    func scheduleAutosave() {
        guard !isRestoringDraft else { return }
        autosaveAction.schedule(after: .milliseconds(900)) {
            saveDraft()
        }
    }

    @discardableResult
    func saveDraft() -> Bool {
        let payload = draftSavePayload()

        if activeDraft == nil {
            guard shouldCreateDraft(payload) else { return true }

            let draft = WritingDraft(
                promptID: prompt.id,
                language: prompt.language,
                paperStyle: payload.paperStyle,
                blackPaperMode: payload.blackPaperMode,
                paperWidth: payload.paperSize.width,
                paperHeight: payload.paperSize.height,
                rulingSpacing: payload.rulingSpacing,
                drawingData: payload.drawingData
            )
            modelContext.insert(draft)
            activeDraft = draft
            return persistDraftChanges(rollbackActiveDraft: true)
        }

        guard let activeDraft else { return true }
        guard activeDraft.apply(payload) else { return true }
        return persistDraftChanges(rollbackActiveDraft: false)
    }
}
