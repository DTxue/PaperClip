import Foundation

extension PDFWorkspaceView {
    func prepareForExamAttemptActivation() -> Bool {
        session.pendingSaveAction.cancel()
        do {
            try flushPendingDrawingsThrowing()
            return true
        } catch {
            session.alert = AppAlert(title: "保存答题失败", error: error)
            return false
        }
    }

    func applyActiveExamAttempt(_ attempt: ExamAttempt, pdfURL: URL) {
        session.activateAttempt(attempt, pdfURL: pdfURL)
    }

    func applyLoadedExamAnswers(_ result: LatestLayersByPage<ExamHandwritingLayer>) {
        session.applyLoadedExamAnswers(result)
        do {
            if try answerLayerStore.deleteDuplicateLayers(result.duplicates) {
                archiveActiveExamAttemptBestEffort()
            }
        } catch {
            session.alert = AppAlert(title: "无法清理重复答题内容", error: error)
        }
    }

    func clearLoadedExamAnswers() {
        session.clearLoadedExamAnswers()
    }

    func exitActiveExam() {
        guard session.activeAttempt != nil else { return }
        session.pendingSaveAction.cancel()
        do {
            try persistModelContextThrowing()
            try archiveActiveExamAttempt()
        } catch {
            session.alert = AppAlert(title: "无法退出考试", message: "当前答题内容保存失败，请稍后重试。\(error.localizedDescription)")
            return
        }

        session.resetAfterExamExit()
        refreshExamSummary()
    }

    func archiveActiveExamAttemptBestEffort() {
        do {
            try archiveActiveExamAttempt()
        } catch {
            assertionFailure("考试记录归档失败：\(error.localizedDescription)")
        }
    }

    func archiveActiveExamAttempt() throws {
        guard let attempt = session.activeAttempt else { return }
        let drawings = try modelContext.fetchExamHandwritingLayers(attemptID: attempt.id)
        let marks = try modelContext.fetchExamGradeMarks(attemptID: attempt.id)
        try PDFExamArchiveStore.archive(attempt: attempt, drawings: drawings, gradeMarks: marks)
    }
}
