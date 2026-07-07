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
            isSubmittingExam: snapshot.isSubmittingExam,
            isWritingEnabled: snapshot.isWritingEnabled,
            isDrawingVisible: snapshot.isDrawingVisible,
            isSelectionMode: snapshot.isSelectionMode,
            onStartExam: { session.isPageSelectionPresented = true },
            onShowHistory: openExamHistory,
            onSubmit: { session.isSubmitConfirmationPresented = true },
            onExport: exportCurrentExamPages,
            onToggleWriting: toggleWritingMode,
            onUndo: { session.undoToken += 1 },
            onRedo: { session.redoToken += 1 },
            onToggleDrawingVisibility: { session.isDrawingVisible.toggle() },
            onClearAnswers: { session.isClearAnswersConfirmationPresented = true },
            onShowScratch: showScratchBoard,
            onToggleSelection: toggleSelectionMode
        )
    }

    func exportCurrentExamPages() {
        session.pendingSaveAction.cancel()
        flushPendingDrawings()
        session.isPDFPageExportPresented = true
    }

    func toggleWritingMode() {
        session.toggleWritingMode()
    }

    func showScratchBoard() {
        session.showScratchBoard()
    }

    func toggleSelectionMode() {
        session.isSelectionMode ? session.leaveSelectionMode() : session.beginSelectionMode()
    }
}
