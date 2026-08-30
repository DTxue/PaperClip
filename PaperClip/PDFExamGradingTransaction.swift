import Foundation
import SwiftData

enum PDFExamGradingTransactionError: LocalizedError {
    case alreadySubmittedOrGraded
    case notSubmitted

    var errorDescription: String? {
        switch self {
        case .alreadySubmittedOrGraded:
            return "这份试卷已经提交或完成批阅，请从考试记录查看结果。"
        case .notSubmitted:
            return "这份试卷还没有完成交卷，不能保存批阅结果。"
        }
    }
}

enum PDFExamGradingTransaction {
    static func beginSubmission(
        attempt: ExamAttempt,
        in modelContext: ModelContext,
        persistPendingChanges: () throws -> Void
    ) throws {
        guard ExamAttemptStatus.canSubmit(attempt.status) else {
            throw PDFExamGradingTransactionError.alreadySubmittedOrGraded
        }

        try persistPendingChanges()

        let now = Date.now
        attempt.status = ExamAttemptStatus.submitted.rawValue
        attempt.submittedAt = now
        attempt.updatedAt = now
        try modelContext.saveOrRollbackIfNeeded()
    }

    static func finishGrading(
        items: [AIExamGradingItem],
        pagePixelSizes: [Int: CGSize] = [:],
        attempt: ExamAttempt,
        sourceDocumentID: UUID,
        in modelContext: ModelContext
    ) throws {
        guard attempt.status == ExamAttemptStatus.submitted.rawValue else {
            throw ExamAttemptStatus(rawValue: attempt.status)?.isTerminal == true
                ? PDFExamGradingTransactionError.alreadySubmittedOrGraded
                : PDFExamGradingTransactionError.notSubmitted
        }

        try modelContext.deleteExamGradeMarks(attemptID: attempt.id)

        let normalizedAnchors = PDFExamGradingSupport.normalizedStampAnchorStrings(
            items.map {
                PDFExamGradingSupport.RawStampAnchor(
                    pageIndex: $0.pageIndex,
                    x: $0.stampAnchor.x,
                    y: $0.stampAnchor.y
                )
            },
            pagePixelSizes: pagePixelSizes
        )

        for (item, normalizedAnchor) in zip(items, normalizedAnchors) {
            let mark = ExamGradeMark(
                sourceDocumentId: sourceDocumentID,
                attemptId: attempt.id,
                pageIndex: item.pageIndex,
                isCorrect: item.isCorrect,
                normalizedAnchor: normalizedAnchor,
                confidence: item.confidence,
                questionNumber: item.questionNumber
            )
            modelContext.insert(mark)
        }

        attempt.status = ExamAttemptStatus.graded.rawValue
        attempt.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
    }

    static func recordGradingFailure(
        attempt: ExamAttempt,
        in modelContext: ModelContext
    ) throws {
        guard ExamAttemptStatus(rawValue: attempt.status)?.isTerminal != true else { return }

        attempt.status = ExamAttemptStatus.submitted.rawValue
        attempt.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
    }
}
