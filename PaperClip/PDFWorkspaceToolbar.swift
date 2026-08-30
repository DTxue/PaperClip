import SwiftUI

extension PDFWorkspaceView {
    var toolbarSnapshot: PDFWorkspaceToolbarSnapshot {
        session.toolbarSnapshot()
    }

    var workspaceToolbarButtons: some View {
        let snapshot = toolbarSnapshot
        return PDFWorkspaceToolbarButtons(
            hasActiveAttempt: snapshot.hasActiveAttempt,
            hasAttempts: snapshot.hasAttempts,
            canSubmitExam: snapshot.canSubmitExam,
            submitExamTitle: snapshot.submitExamTitle,
            submitExamSystemImage: snapshot.submitExamSystemImage,
            isSubmittingExam: snapshot.isSubmittingExam,
            canEditAnswers: snapshot.canEditAnswers,
            isWritingEnabled: snapshot.isWritingEnabled,
            isDrawingVisible: snapshot.isDrawingVisible,
            onStartExam: startOrResumeFullExam,
            onShowHistory: openExamHistory,
            onSubmit: { session.isSubmitConfirmationPresented = true },
            onExport: exportCurrentExamPages,
            onToggleWriting: toggleWritingMode,
            onUndo: { session.undoToken += 1 },
            onRedo: { session.redoToken += 1 },
            onToggleDrawingVisibility: { session.isDrawingVisible.toggle() },
            onClearAnswers: { session.isClearAnswersConfirmationPresented = true },
            onShowScratch: showScratchBoard
        )
    }

    func exportCurrentExamPages() {
        session.pendingSaveAction.cancel()
        _ = flushPendingDrawings()
        guard session.pendingDrawingStore.isEmpty else {
            scheduleModelContextSave()
            return
        }
        session.isPDFPageExportPresented = true
    }

    func toggleWritingMode() {
        session.toggleWritingMode()
    }

    func showScratchBoard() {
        session.showScratchBoard()
    }
}
