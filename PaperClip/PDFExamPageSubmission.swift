import Foundation
import SwiftData

enum PDFExamPageSubmissionError: LocalizedError {
    case invalidPage
    case alreadySubmitted
    case alreadyGraded
    case pageNotUnlocked
    case attemptNotInProgress
    case submissionMismatch

    var errorDescription: String? {
        switch self {
        case .invalidPage:
            return "该页面不属于当前考试。"
        case .alreadySubmitted:
            return "该页面已经提交，不能重复提交。"
        case .alreadyGraded:
            return "该页面已经批阅完成，不能重复批阅。"
        case .pageNotUnlocked:
            return "上一页尚未完成批阅，当前页面还不能开始考试。"
        case .attemptNotInProgress:
            return "当前考试已完成交卷，不能继续提交页面。"
        case .submissionMismatch:
            return "单页提交记录与当前考试不匹配。"
        }
    }
}

@MainActor
enum PDFExamPageSubmissionTransaction {
    static func beginSubmission(
        attempt: ExamAttempt,
        pageIndex: Int,
        in modelContext: ModelContext,
        persistPendingChanges: () throws -> Void
    ) throws -> ExamPageSubmission {
        guard ExamAttemptStatus(rawValue: attempt.status) == .inProgress else {
            throw PDFExamPageSubmissionError.attemptNotInProgress
        }
        guard attempt.selectedPageIndices.contains(pageIndex) else {
            throw PDFExamPageSubmissionError.invalidPage
        }
        guard try modelContext.fetchExamPageSubmission(
            attemptID: attempt.id,
            pageIndex: pageIndex
        ) == nil else {
            throw PDFExamPageSubmissionError.alreadySubmitted
        }

        let existing = try modelContext.fetchExamPageSubmissions(attemptID: attempt.id)
        let decision = PDFExamResumePolicy.decide(
            pageIndices: attempt.selectedPageIndices,
            submissions: existing,
            pagesWithAnswers: []
        )
        guard decision.target.pageIndex == pageIndex else {
            throw PDFExamPageSubmissionError.pageNotUnlocked
        }

        try persistPendingChanges()

        let now = Date.now
        let submission = ExamPageSubmission(
            sourceDocumentId: attempt.sourceDocumentId,
            attemptId: attempt.id,
            pageIndex: pageIndex,
            submittedAt: now,
            updatedAt: now
        )
        modelContext.insert(submission)

        let progress = PDFExamPageProgress(
            pageIndices: attempt.selectedPageIndices,
            submissions: existing + [submission]
        )
        attempt.updatedAt = now
        if progress.isFullySubmitted {
            attempt.status = ExamAttemptStatus.submitted.rawValue
            attempt.submittedAt = now
        }
        try modelContext.saveOrRollbackIfNeeded()
        return submission
    }

    static func finishGrading(
        items: [AIExamGradingItem],
        targetPageIndex: Int,
        pagePixelSize: CGSize,
        submission: ExamPageSubmission,
        attempt: ExamAttempt,
        in modelContext: ModelContext
    ) throws {
        guard submission.attemptId == attempt.id,
              submission.pageIndex == targetPageIndex,
              attempt.selectedPageIndices.contains(targetPageIndex),
              let submissionStatus = ExamPageSubmissionStatus(rawValue: submission.status)
        else {
            throw PDFExamPageSubmissionError.submissionMismatch
        }
        guard submissionStatus == .submitted else {
            throw PDFExamPageSubmissionError.alreadyGraded
        }

        try modelContext.deleteExamGradeMarks(
            attemptID: attempt.id,
            pageIndex: targetPageIndex
        )

        // 单页请求里的模型 pageIndex 恒为 0；持久化必须使用真实 PDF 页码。
        let normalizedAnchors = PDFExamGradingSupport.normalizedStampAnchorStrings(
            items.map { item in
                PDFExamGradingSupport.RawStampAnchor(
                    pageIndex: targetPageIndex,
                    x: item.stampAnchor.x,
                    y: item.stampAnchor.y
                )
            },
            pagePixelSizes: [targetPageIndex: pagePixelSize]
        )

        for (item, normalizedAnchor) in zip(items, normalizedAnchors) {
            modelContext.insert(ExamGradeMark(
                sourceDocumentId: attempt.sourceDocumentId,
                attemptId: attempt.id,
                pageIndex: targetPageIndex,
                isCorrect: item.isCorrect,
                normalizedAnchor: normalizedAnchor,
                confidence: item.confidence,
                questionNumber: item.questionNumber
            ))
        }

        let now = Date.now
        submission.status = ExamPageSubmissionStatus.graded.rawValue
        submission.gradedAt = now
        submission.updatedAt = now
        attempt.updatedAt = now

        let submissions = try modelContext.fetchExamPageSubmissions(attemptID: attempt.id)
        let progress = PDFExamPageProgress(
            pageIndices: attempt.selectedPageIndices,
            submissions: submissions
        )
        if progress.isFullyGraded {
            attempt.status = ExamAttemptStatus.graded.rawValue
        } else if progress.isFullySubmitted {
            attempt.status = ExamAttemptStatus.submitted.rawValue
        } else {
            attempt.status = ExamAttemptStatus.inProgress.rawValue
        }
        try modelContext.saveOrRollbackIfNeeded()
    }
}

extension ModelContext {
    @discardableResult
    func deleteExamGradeMarks(attemptID: UUID, pageIndex: Int) throws -> Int {
        var descriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID && mark.pageIndex == pageIndex
            }
        )
        descriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
        return try deleteFetched(descriptor)
    }
}
