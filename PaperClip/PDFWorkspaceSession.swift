import SwiftUI

/// PDF workspace 的会话状态 module。
///
/// 原生能力评估：导航、弹窗、分享、PDF 阅读和 PencilKit 画笔仍由 SwiftUI、
/// PDFKit、ShareLink 和 PKToolPicker 承担；本 module 只集中 PaperClip 的业务状态：
/// 考试 attempt 生命周期、答题图层缓存、框选动作、导出 sheet 和异步任务槽。
@MainActor
struct PDFWorkspaceSession {
    var latestAttempt: ExamAttemptHistoryRowData?
    var attemptCount = 0
    var examHistoryAttempts: [ExamAttemptHistoryRowData] = []
    var drawings: [Int: Data] = [:]
    var examHandwritingByPage: [Int: ExamHandwritingLayer] = [:]
    var activeGradeMarks: [ExamGradeMark] = []
    var activeAttempt: ExamAttempt?
    var activeExamPDFURL: URL?
    var isPageSelectionPresented = false
    var isExamHistoryPresented = false
    var isSubmitConfirmationPresented = false
    var isExitExamConfirmationPresented = false
    var isSubmittingExam = false
    var isWritingEnabled = false
    var isDrawingVisible = true
    var isScratchPresented = false
    var isSelectionMode = false
    var selectionRect: CGRect?
    var pendingSelectionAction: PDFSelectionAction?
    var selectionActionToken = 0
    var cancelSelectionToken = 0
    var undoToken = 0
    var redoToken = 0
    var clearAnswersToken = 0
    var reloadDrawingsToken = 0
    var currentCard: MistakeCard?
    var aiAnalysisRequest: AIAnalysisRequest?
    var shareImageRequest: ShareImageRequest?
    var isPDFPageExportPresented = false
    var canvasSizes: [Int: CGSize] = [:]
    var alert: AppAlert?
    var isClearAnswersConfirmationPresented = false
    var pendingSaveAction = DebouncedAction()
    var pendingDrawingStore = PDFPendingDrawingStore()
    var submitTaskSlot = ViewTaskSlot()
    var selectionActionTaskSlot = ViewTaskSlot()

    func activePDFURL(for document: PDFDocumentItem) -> URL {
        activeExamPDFURL ?? document.localFileURL
    }

    func workspaceSnapshot() -> PDFWorkspaceSnapshot {
        PDFWorkspaceSnapshot(
            latestAttempt: latestAttempt,
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
            isWritingEnabled: isWritingEnabled,
            isDrawingVisible: isDrawingVisible,
            isSelectionMode: isSelectionMode,
            isSubmittingExam: isSubmittingExam
        )
    }

    func toolbarSnapshot() -> PDFWorkspaceToolbarSnapshot {
        PDFWorkspaceToolbarSnapshot(
            activeAttempt: activeAttempt,
            hasAttempts: workspaceSnapshot().hasAttempts,
            isSubmittingExam: isSubmittingExam,
            isWritingEnabled: isWritingEnabled,
            isDrawingVisible: isDrawingVisible,
            isSelectionMode: isSelectionMode
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
        state.recordInserted(ExamAttemptHistoryRowData(attempt: attempt))
        applyExamHistoryState(state)
    }

    mutating func noteExamAttemptUpdated(_ attempt: ExamAttempt) {
        var state = currentExamHistoryState()
        state.recordUpdated(ExamAttemptHistoryRowData(attempt: attempt))
        applyExamHistoryState(state)
    }

    mutating func leaveSelectionMode() {
        guard isSelectionMode else { return }
        selectionRect = nil
        isSelectionMode = false
    }

    mutating func beginSelectionMode() {
        isWritingEnabled = false
        isSelectionMode = true
    }

    mutating func toggleWritingMode() {
        leaveSelectionMode()
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

    mutating func activateAttempt(_ attempt: ExamAttempt, pdfURL: URL) {
        activeAttempt = attempt
        activeExamPDFURL = pdfURL
        isWritingEnabled = PDFExamActivationDefaults.isWritingEnabled
        isDrawingVisible = PDFExamActivationDefaults.isDrawingVisible
        leaveSelectionMode()
        reloadDrawingsToken += 1
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
        activeGradeMarks = []
        clearLoadedExamAnswers()
        pendingDrawingStore.removeAll()
        leaveSelectionMode()
        isWritingEnabled = false
        isDrawingVisible = true
        isScratchPresented = false
        isPDFPageExportPresented = false
        reloadDrawingsToken += 1
    }

    mutating func resetActiveExamURL() {
        activeExamPDFURL = nil
    }
}
