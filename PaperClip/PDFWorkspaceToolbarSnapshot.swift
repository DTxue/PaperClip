struct PDFWorkspaceToolbarSnapshot {
    let hasActiveAttempt: Bool
    let hasAttempts: Bool
    let canSubmitExam: Bool
    let isSubmittingExam: Bool
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let isSelectionMode: Bool

    init(
        activeAttempt: ExamAttempt?,
        hasAttempts: Bool,
        isSubmittingExam: Bool,
        isWritingEnabled: Bool,
        isDrawingVisible: Bool,
        isSelectionMode: Bool
    ) {
        self.hasActiveAttempt = activeAttempt != nil
        self.hasAttempts = hasAttempts
        self.canSubmitExam = activeAttempt.map { ExamAttemptStatus.canSubmit($0.status) } ?? false
        self.isSubmittingExam = isSubmittingExam
        self.isWritingEnabled = isWritingEnabled
        self.isDrawingVisible = isDrawingVisible
        self.isSelectionMode = isSelectionMode
    }
}
