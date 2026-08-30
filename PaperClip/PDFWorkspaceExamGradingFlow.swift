import SwiftUI
import UIKit

extension PDFWorkspaceView {
    func submitExam() {
        guard let attempt = session.activeAttempt else { return }
        do {
            let pdfURL = try ensureExamPDFCache(for: attempt)
            let usesFullDocumentPageIndices = session.activeExamUsesFullDocument
            let isLegacyCompletedAttempt = attempt.status != ExamAttemptStatus.inProgress.rawValue
                && session.pageSubmissionsByPage.isEmpty
            if !usesFullDocumentPageIndices || isLegacyCompletedAttempt {
                submitLegacyExam()
                return
            }
            try submitCurrentExamPage(attempt: attempt, pdfURL: pdfURL)
        } catch {
            if !session.pendingDrawingStore.isEmpty {
                scheduleModelContextSave()
            }
            session.alert = AppAlert(title: "提交当前页失败", error: error)
        }
    }

    private func submitCurrentExamPage(attempt: ExamAttempt, pdfURL: URL) throws {
        guard !session.isSubmittingExam else { return }

        let pageIndex: Int
        var existingSubmission: ExamPageSubmission?
        if ExamAttemptStatus(rawValue: attempt.status) == .inProgress {
            guard let target = session.activeResumeDecision()?.target else {
                throw PDFExamPageSubmissionError.attemptNotInProgress
            }
            switch target {
            case let .retryGrading(targetPageIndex):
                guard let existing = session.pageSubmissionsByPage[targetPageIndex] else {
                    throw PDFExamPageSubmissionError.submissionMismatch
                }
                pageIndex = targetPageIndex
                existingSubmission = existing
            case let .resumeDraft(targetPageIndex), let .startNextPage(targetPageIndex):
                pageIndex = targetPageIndex
                existingSubmission = nil
            case .roundCompleted:
                throw PDFExamPageSubmissionError.attemptNotInProgress
            }
        } else {
            guard let pendingPageIndex = attempt.selectedPageIndices.first(where: {
                session.pageSubmissionsByPage[$0]?.status == ExamPageSubmissionStatus.submitted.rawValue
            }), let existing = session.pageSubmissionsByPage[pendingPageIndex] else {
                throw PDFExamPageSubmissionError.alreadySubmitted
            }
            pageIndex = pendingPageIndex
            existingSubmission = existing
        }

        guard session.currentPDFPageIndex == pageIndex else {
            session.requestedPDFPageIndex = pageIndex
            session.pageNavigationToken += 1
            session.alert = AppAlert(
                title: "已定位到第 \(pageIndex + 1) 页",
                message: "请确认当前页面内容后再次提交。"
            )
            return
        }

        session.pendingSaveAction.cancel()
        _ = try persistModelContextThrowing()
        let renderedPage = try ExamPageImageRenderer.renderPageJPEGData(
            pdfURL: pdfURL,
            pageIndex: pageIndex,
            drawingData: session.drawings[pageIndex],
            canvasSize: session.canvasSizes[pageIndex]
        )
        let submission: ExamPageSubmission
        if let existingSubmission {
            submission = existingSubmission
        } else {
            let created = try PDFExamPageSubmissionTransaction.beginSubmission(
                attempt: attempt,
                pageIndex: pageIndex,
                in: modelContext,
                persistPendingChanges: {}
            )
            session.pageSubmissionsByPage[pageIndex] = created
            session.currentAttemptSummary = attempt.status == ExamAttemptStatus.inProgress.rawValue
                ? ExamAttemptHistoryRowData(attempt: attempt)
                : nil
            noteExamAttemptUpdated(attempt)
            archiveActiveExamAttemptBestEffort()
            submission = created
        }
        session.isSubmittingExam = true
        session.submitTaskSlot.cancel()
        _ = session.submitTaskSlot.start { taskID in
            await gradeSubmittedPage(
                renderedPage,
                pageIndex: pageIndex,
                submission: submission,
                attempt: attempt,
                taskID: taskID
            )
            session.submitTaskSlot.finish(taskID)
        }
    }

    @MainActor
    private func gradeSubmittedPage(
        _ renderedPage: ExamPageImageRenderer.PageRenderResult,
        pageIndex: Int,
        submission: ExamPageSubmission,
        attempt: ExamAttempt,
        taskID: UUID
    ) async {
        do {
            let grading = try await AIService.gradeExamPage(jpegData: renderedPage.jpegData)
            try Task.checkCancellation()
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            try PDFExamPageSubmissionTransaction.finishGrading(
                items: grading.items,
                targetPageIndex: pageIndex,
                pagePixelSize: renderedPage.pixelSize,
                submission: submission,
                attempt: attempt,
                in: modelContext
            )
            session.pageSubmissionsByPage[pageIndex] = submission
            noteExamAttemptUpdated(attempt)
            refreshGradeMarks(for: attempt)
            archiveActiveExamAttemptBestEffort()
            session.isSubmittingExam = false
            if attempt.status == ExamAttemptStatus.inProgress.rawValue {
                session.currentAttemptSummary = ExamAttemptHistoryRowData(attempt: attempt)
                session.navigateToNextUnsubmittedPage()
            } else {
                session.currentAttemptSummary = nil
            }
            session.alert = AppAlert(
                title: "第 \(pageIndex + 1) 页批阅完成",
                message: attempt.status == ExamAttemptStatus.graded.rawValue
                    ? "整份 PDF 已完成提交和批阅，现在可以开始下一轮。"
                    : "该页答案已锁定，历史批阅结果会继续保留在当前考试中。"
            )
        } catch is CancellationError {
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            session.isSubmittingExam = false
        } catch {
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            session.isSubmittingExam = false
            if attempt.status == ExamAttemptStatus.inProgress.rawValue {
                session.navigateToNextUnsubmittedPage()
            }
            archiveActiveExamAttemptBestEffort()
            session.alert = AppAlert(
                title: "第 \(pageIndex + 1) 页已保存，批阅失败",
                message: "答案已经锁定且不会丢失，请重试批阅；完成后才能继续下一页。\(error.localizedDescription)"
            )
        }
    }

    private func submitLegacyExam() {
        guard let attempt = session.activeAttempt else { return }
        let status = ExamAttemptStatus(rawValue: attempt.status)
        guard status?.canRequestGrading == true, !session.isSubmittingExam else {
            session.alert = AppAlert(title: "不能重复交卷", message: "这份试卷已经提交或完成批阅，请从考试记录查看结果。")
            return
        }
        session.submitTaskSlot.cancel()
        session.pendingSaveAction.cancel()

        if status?.canSubmit == true {
            do {
                try PDFExamGradingTransaction.beginSubmission(
                    attempt: attempt,
                    in: modelContext,
                    persistPendingChanges: { _ = try persistModelContextThrowing() }
                )
                noteExamAttemptUpdated(attempt)
                archiveActiveExamAttemptBestEffort()
            } catch PDFExamGradingTransactionError.alreadySubmittedOrGraded {
                session.alert = AppAlert(title: "不能重复交卷", message: "这份试卷已经提交或完成批阅，请从考试记录查看结果。")
                return
            } catch {
                if !session.pendingDrawingStore.isEmpty {
                    scheduleModelContextSave()
                }
                session.alert = AppAlert(title: "交卷失败", error: error)
                return
            }
        } else {
            do {
                if try persistModelContextThrowing() {
                    archiveActiveExamAttemptBestEffort()
                }
            } catch {
                if !session.pendingDrawingStore.isEmpty {
                    scheduleModelContextSave()
                }
                session.alert = AppAlert(title: "重新批阅失败", message: "当前答题内容保存失败，请稍后重试。\(error.localizedDescription)")
                return
            }
        }
        session.isSubmittingExam = true

        _ = session.submitTaskSlot.start { taskID in
            await gradeSubmittedExam(attempt, taskID: taskID)
            session.submitTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func gradeSubmittedExam(_ attempt: ExamAttempt, taskID: UUID) async {
        do {
            let pageJPEGData = try renderExamPageJPEGData(for: attempt)
            try Task.checkCancellation()
            let grading = try await AIService.gradeExam(pageJPEGData: pageJPEGData)
            try Task.checkCancellation()
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            try PDFExamGradingTransaction.finishGrading(
                items: grading.items,
                pagePixelSizes: gradingPagePixelSizes(from: pageJPEGData),
                attempt: attempt,
                sourceDocumentID: document.id,
                in: modelContext
            )
            noteExamAttemptUpdated(attempt)
            refreshGradeMarks(for: attempt)
            archiveActiveExamAttemptBestEffort()
            session.isSubmittingExam = false
            session.alert = AppAlert(
                title: "批阅完成",
                message: "已根据豆包反馈自动放置正确和错误印章。源 PDF 未被修改。"
            )
        } catch is CancellationError {
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            session.isSubmittingExam = false
        } catch PDFExamGradingTransactionError.alreadySubmittedOrGraded {
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            noteExamAttemptUpdated(attempt)
            refreshGradeMarks(for: attempt)
            session.isSubmittingExam = false
            session.alert = AppAlert(title: "不能重复交卷", message: "这份试卷已经提交或完成批阅，请从考试记录查看结果。")
        } catch {
            guard session.submitTaskSlot.isCurrent(taskID) else { return }
            do {
                try PDFExamGradingTransaction.recordGradingFailure(
                    attempt: attempt,
                    in: modelContext
                )
            } catch {
                session.alert = AppAlert(title: "交卷批阅失败，且保存状态失败", error: error)
                session.isSubmittingExam = false
                return
            }
            noteExamAttemptUpdated(attempt)
            archiveActiveExamAttemptBestEffort()
            session.isSubmittingExam = false
            session.alert = AppAlert(title: "交卷批阅失败", error: error)
        }
    }

    func renderExamPageJPEGData(for attempt: ExamAttempt) throws -> [Data] {
        let pdfURL = try ensureExamPDFCache(for: attempt)
        return try ExamPageImageRenderer.renderJPEGData(
            pdfURL: pdfURL,
            drawings: session.drawings,
            canvasSizes: session.canvasSizes
        )
    }

    private func gradingPagePixelSizes(from pageJPEGData: [Data]) -> [Int: CGSize] {
        var pagePixelSizes: [Int: CGSize] = [:]
        pagePixelSizes.reserveCapacity(pageJPEGData.count)
        for (pageIndex, data) in pageJPEGData.enumerated() {
            guard let cgImage = UIImage(data: data)?.cgImage else { continue }
            pagePixelSizes[pageIndex] = CGSize(
                width: cgImage.width,
                height: cgImage.height
            )
        }
        return pagePixelSizes
    }
}
