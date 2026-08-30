import SwiftUI

/// PDF workspace 的会话状态 module。
///
/// 原生能力评估：导航、弹窗、分享、PDF 阅读和 PencilKit 画笔仍由 SwiftUI、
/// PDFKit、ShareLink 和 PKToolPicker 承担；本 module 只集中 PaperClip 的业务状态：
/// 考试 attempt 生命周期、答题图层缓存、导出 sheet 和异步任务槽。
@MainActor
struct PDFWorkspaceSession {
    var latestAttempt: ExamAttemptHistoryRowData?
    var attemptCount = 0
    var examHistoryAttempts: [ExamAttemptHistoryRowData] = []
    var currentAttemptSummary: ExamAttemptHistoryRowData?
    var drawings: [Int: Data] = [:]
    var examHandwritingByPage: [Int: ExamHandwritingLayer] = [:]
    var pageSubmissionsByPage: [Int: ExamPageSubmission] = [:]
    var activeGradeMarks: [ExamGradeMark] = []
    var activeAttempt: ExamAttempt?
    var activeExamPDFURL: URL?
    var activeExamUsesFullDocument = false
    var examPageSelectionContext: PDFExamPageSelectionContext?
    var isExamHistoryPresented = false
    var isSubmitConfirmationPresented = false
    var isExitExamConfirmationPresented = false
    var isSubmittingExam = false
    var isWritingEnabled = false
    var isDrawingVisible = true
    var isScratchPresented = false
    var undoToken = 0
    var redoToken = 0
    var clearAnswersToken = 0
    var reloadDrawingsToken = 0
    var isPDFPageExportPresented = false
    var canvasSizes: [Int: CGSize] = [:]
    var currentPDFPageIndex: Int?
    var requestedPDFPageIndex: Int?
    var pageNavigationToken = 0
    var alert: AppAlert?
    var isClearAnswersConfirmationPresented = false
    var pendingSaveAction = DebouncedAction()
    var pendingDrawingStore = PDFPendingDrawingStore()
    var submitTaskSlot = ViewTaskSlot()

    func activePDFURL(for document: PDFDocumentItem) -> URL {
        activeExamPDFURL ?? document.localFileURL
    }

    func workspaceSnapshot() -> PDFWorkspaceSnapshot {
        PDFWorkspaceSnapshot(
            latestAttempt: latestAttempt,
            currentAttempt: currentAttemptSummary,
            attemptCount: attemptCount,
            activeGradeMarks: activeGradeMarks,
            activeAttempt: activeAttempt
        )
    }

    func canvasSnapshot(for document: PDFDocumentItem) -> PDFWorkspaceCanvasSnapshot {
        PDFWorkspaceCanvasSnapshot(
            activePDFURL: activePDFURL(for: document),
            drawings: drawings,
            workspaceSnapshot: workspaceSnapshot(),
            hasActiveAttempt: activeAttempt != nil,
            activeAttempt: activeAttempt,
            pageProgress: activePageProgress(),
            currentPageIndex: currentPDFPageIndex,
            resumeTarget: activeResumeDecision()?.target,
            isWritingEnabled: isWritingEnabled,
            isDrawingVisible: isDrawingVisible,
            isSubmittingExam: isSubmittingExam
        )
    }

    func toolbarSnapshot() -> PDFWorkspaceToolbarSnapshot {
        PDFWorkspaceToolbarSnapshot(
            activeAttempt: activeAttempt,
            pageProgress: activePageProgress(),
            currentPageIndex: currentPDFPageIndex,
            resumeTarget: activeResumeDecision()?.target,
            hasAttempts: workspaceSnapshot().hasAttempts,
            isSubmittingExam: isSubmittingExam,
            isWritingEnabled: isWritingEnabled,
            isDrawingVisible: isDrawingVisible
        )
    }

    func currentExamHistoryState() -> ExamAttemptHistoryState {
        ExamAttemptHistoryState(
            latestAttempt: latestAttempt,
            attemptCount: attemptCount,
            attempts: examHistoryAttempts
        )
    }

    mutating func applyExamHistoryState(_ state: ExamAttemptHistoryState) {
        latestAttempt = state.latestAttempt
        attemptCount = state.attemptCount
        examHistoryAttempts = state.attempts
    }

    mutating func noteExamAttemptInserted(_ attempt: ExamAttempt) {
        var state = currentExamHistoryState()
        state.recordInserted(historyRowData(for: attempt))
        applyExamHistoryState(state)
    }

    mutating func noteExamAttemptUpdated(_ attempt: ExamAttempt) {
        var state = currentExamHistoryState()
        state.recordUpdated(historyRowData(for: attempt))
        applyExamHistoryState(state)
    }

    private func historyRowData(for attempt: ExamAttempt) -> ExamAttemptHistoryRowData {
        let progress = activeAttempt?.id == attempt.id ? activePageProgress() : nil
        return ExamAttemptHistoryRowData(attempt: attempt, pageProgress: progress)
    }

    mutating func toggleWritingMode() {
        guard activeAttempt?.status == ExamAttemptStatus.inProgress.rawValue else { return }
        isDrawingVisible = true
        isWritingEnabled.toggle()
    }

    mutating func showScratchBoard() {
        isWritingEnabled = false
        isScratchPresented = true
    }

    mutating func closeScratchBoard() {
        isScratchPresented = false
    }

    mutating func activateAttempt(
        _ attempt: ExamAttempt,
        pdfURL: URL,
        usesFullDocument: Bool
    ) {
        activeAttempt = attempt
        activeExamPDFURL = pdfURL
        activeExamUsesFullDocument = usesFullDocument
        isWritingEnabled = attempt.status == ExamAttemptStatus.inProgress.rawValue
        isDrawingVisible = PDFExamActivationDefaults.isDrawingVisible
        reloadDrawingsToken += 1
    }

    mutating func applyLoadedPageSubmissions(_ submissions: [ExamPageSubmission]) {
        pageSubmissionsByPage = Dictionary(
            uniqueKeysWithValues: submissions.map { ($0.pageIndex, $0) }
        )
    }

    func activePageProgress() -> PDFExamPageProgress? {
        guard let activeAttempt,
              activeExamUsesFullDocument
        else { return nil }
        return PDFExamPageProgress(
            pageIndices: activeAttempt.selectedPageIndices,
            submissions: Array(pageSubmissionsByPage.values)
        )
    }

    func activeResumeDecision() -> PDFExamResumeDecision? {
        guard let activeAttempt,
              activePageProgress() != nil
        else { return nil }
        return PDFExamResumePolicy.decide(
            pageIndices: activeAttempt.selectedPageIndices,
            submissions: Array(pageSubmissionsByPage.values),
            pagesWithAnswers: Set(examHandwritingByPage.keys)
        )
    }

    func writablePageIndices() -> Set<Int>? {
        guard let decision = activeResumeDecision() else { return nil }
        switch decision.target {
        case let .resumeDraft(pageIndex), let .startNextPage(pageIndex):
            return Set([pageIndex])
        case .retryGrading, .roundCompleted:
            return []
        }
    }

    func isCurrentPageAwaitingGrading() -> Bool {
        guard let currentPDFPageIndex else { return false }
        return activePageProgress()?.isAwaitingGrading(pageIndex: currentPDFPageIndex) == true
    }

    mutating func navigateToNextUnsubmittedPage() {
        guard let pageIndex = activeResumeDecision()?.target.pageIndex
            ?? activePageProgress()?.nextUnsubmittedPageIndex
        else { return }
        navigateToExamPage(pageIndex)
    }

    mutating func navigateToExamPage(_ pageIndex: Int) {
        requestedPDFPageIndex = pageIndex
        pageNavigationToken += 1
    }

    mutating func applyLoadedExamAnswers(_ result: LatestLayersByPage<ExamHandwritingLayer>) {
        examHandwritingByPage = result.latest
        drawings = result.latest.mapValues(\.drawingData)
    }

    mutating func clearLoadedExamAnswers() {
        examHandwritingByPage = [:]
        drawings = [:]
    }

    mutating func resetAfterExamExit() {
        activeAttempt = nil
        activeExamPDFURL = nil
        activeExamUsesFullDocument = false
        activeGradeMarks = []
        pageSubmissionsByPage = [:]
        examPageSelectionContext = nil
        currentPDFPageIndex = nil
        requestedPDFPageIndex = nil
        clearLoadedExamAnswers()
        pendingDrawingStore.removeAll()
        isWritingEnabled = false
        isDrawingVisible = true
        isScratchPresented = false
        isPDFPageExportPresented = false
        reloadDrawingsToken += 1
    }

    mutating func resetActiveExamURL() {
        activeExamPDFURL = nil
        activeExamUsesFullDocument = false
    }
}
