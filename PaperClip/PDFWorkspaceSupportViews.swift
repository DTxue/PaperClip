import SwiftUI
import UniformTypeIdentifiers

struct ShareImageRequest: Identifiable, Transferable, Sendable {
    let id = UUID()
    let data: Data

    var image: UIImage? { UIImage(data: data) }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .image) { request in
            request.data
        }
    }
}

struct PDFWorkspaceSnapshot {
    let latestAttempt: ExamAttemptHistoryRowData?
    let currentAttempt: ExamAttemptHistoryRowData?
    let attemptCount: Int
    let gradeStamps: [PDFGradeStamp]

    var hasAttempts: Bool { attemptCount > 0 }

    init(
        latestAttempt: ExamAttemptHistoryRowData?,
        currentAttempt: ExamAttemptHistoryRowData?,
        attemptCount: Int,
        activeGradeMarks: [ExamGradeMark],
        activeAttempt: ExamAttempt?
    ) {
        self.latestAttempt = latestAttempt
        self.currentAttempt = currentAttempt
        self.attemptCount = attemptCount

        guard let activeAttempt else {
            gradeStamps = []
            return
        }

        var activeGradeStamps: [PDFGradeStamp] = []
        for mark in activeGradeMarks where mark.attemptId == activeAttempt.id {
            guard let point = Self.normalizedPoint(from: mark.normalizedAnchor) else { continue }
            activeGradeStamps.append(
                PDFGradeStamp(
                    id: mark.id,
                    pageIndex: mark.pageIndex,
                    isCorrect: mark.isCorrect,
                    normalizedAnchor: point,
                    confidence: mark.confidence
                )
            )
        }
        gradeStamps = activeGradeStamps
    }

    private static func normalizedPoint(from string: String) -> CGPoint? {
        let parts = string
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard parts.count == 2 else { return nil }
        return CGPoint(x: parts[0], y: parts[1])
    }
}

struct PDFWorkspaceCanvasSnapshot {
    let url: URL
    let drawings: [Int: Data]
    let gradeStamps: [PDFGradeStamp]
    let hasActiveAttempt: Bool
    let activeAttemptStartedAt: Date?
    let gradingActionState: PDFExamGradingActionState
    let pageProgress: PDFExamPageProgress?
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let showsStartOverlay: Bool
    let latestAttempt: ExamAttemptHistoryRowData?
    let currentAttempt: ExamAttemptHistoryRowData?
    let attemptCount: Int
    let isSubmittingExam: Bool

    init(
        activePDFURL: URL,
        drawings: [Int: Data],
        workspaceSnapshot: PDFWorkspaceSnapshot,
        hasActiveAttempt: Bool,
        activeAttempt: ExamAttempt?,
        pageProgress: PDFExamPageProgress?,
        currentPageIndex: Int?,
        resumeTarget: PDFExamResumeTarget?,
        isWritingEnabled: Bool,
        isDrawingVisible: Bool,
        isSubmittingExam: Bool
    ) {
        self.url = activePDFURL
        self.drawings = drawings
        self.gradeStamps = workspaceSnapshot.gradeStamps
        self.hasActiveAttempt = hasActiveAttempt
        self.activeAttemptStartedAt = activeAttempt?.createdAt
        self.pageProgress = pageProgress
        self.gradingActionState = PDFExamGradingActionState(
            status: activeAttempt.flatMap { ExamAttemptStatus(rawValue: $0.status) },
            isSubmitting: isSubmittingExam,
            pageProgress: pageProgress,
            currentPageIndex: currentPageIndex,
            resumeTarget: resumeTarget
        )
        self.isWritingEnabled = hasActiveAttempt && isWritingEnabled
        self.isDrawingVisible = isDrawingVisible
        self.showsStartOverlay = !hasActiveAttempt
        self.latestAttempt = workspaceSnapshot.latestAttempt
        self.currentAttempt = workspaceSnapshot.currentAttempt
        self.attemptCount = workspaceSnapshot.attemptCount
        self.isSubmittingExam = isSubmittingExam
    }
}
