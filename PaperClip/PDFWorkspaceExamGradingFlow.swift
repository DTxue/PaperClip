import SwiftUI

extension PDFWorkspaceView {
    func submitExam() {
        guard let attempt = session.activeAttempt else { return }
        guard ExamAttemptStatus.canSubmit(attempt.status), !session.isSubmittingExam else {
            session.alert = AppAlert(title: "不能重复交卷", message: "这份试卷已经提交或完成批阅，请从考试记录查看结果。")
            return
        }
        session.submitTaskSlot.cancel()
        session.pendingSaveAction.cancel()
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
            session.alert = AppAlert(title: "交卷失败", error: error)
            return
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
}
