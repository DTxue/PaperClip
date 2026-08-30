struct PDFWorkspaceToolbarSnapshot {
    let hasActiveAttempt: Bool
    let hasAttempts: Bool
    let canSubmitExam: Bool
    let submitExamTitle: String
    let submitExamSystemImage: String
    let isSubmittingExam: Bool
    let canEditAnswers: Bool
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool

    init(
        activeAttempt: ExamAttempt?,
        pageProgress: PDFExamPageProgress? = nil,
        currentPageIndex: Int? = nil,
        resumeTarget: PDFExamResumeTarget? = nil,
        hasAttempts: Bool,
        isSubmittingExam: Bool,
        isWritingEnabled: Bool,
        isDrawingVisible: Bool
    ) {
        let actionState = PDFExamGradingActionState(
            status: activeAttempt.flatMap { ExamAttemptStatus(rawValue: $0.status) },
            isSubmitting: isSubmittingExam,
            pageProgress: pageProgress,
            currentPageIndex: currentPageIndex,
            resumeTarget: resumeTarget
        )
        self.hasActiveAttempt = activeAttempt != nil
        self.hasAttempts = hasAttempts
        self.canSubmitExam = actionState.isEnabled
        self.submitExamTitle = actionState.title
        self.submitExamSystemImage = actionState.systemImage
        self.isSubmittingExam = isSubmittingExam
        self.canEditAnswers = activeAttempt?.status == ExamAttemptStatus.inProgress.rawValue
        self.isWritingEnabled = isWritingEnabled
        self.isDrawingVisible = isDrawingVisible
    }
}
