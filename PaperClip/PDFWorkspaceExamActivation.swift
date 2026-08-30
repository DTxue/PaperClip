import Foundation

extension PDFWorkspaceView {
    func finishWorkspace() {
        session.pendingSaveAction.cancel()
        do {
            try persistModelContextThrowing()
            try archiveActiveExamAttempt()
        } catch {
            if session.activeAttempt != nil && !session.pendingDrawingStore.isEmpty {
                scheduleModelContextSave()
            }
            session.alert = AppAlert(
                title: "无法关闭试卷",
                message: "当前答题内容尚未安全保存，请稍后重试。\(error.localizedDescription)"
            )
            return
        }
        dismiss()
    }

    func prepareForExamAttemptActivation() -> Bool {
        session.pendingSaveAction.cancel()
        do {
            try flushPendingDrawingsThrowing()
            return true
        } catch {
            if !session.pendingDrawingStore.isEmpty {
                scheduleModelContextSave()
            }
            session.alert = AppAlert(title: "保存答题失败", error: error)
            return false
        }
    }

    func applyActiveExamAttempt(_ attempt: ExamAttempt, pdfURL: URL) {
        let sourcePageCount = PDFPageDocumentReader.pageCount(in: document.localFileURL)
        session.activateAttempt(
            attempt,
            pdfURL: pdfURL,
            usesFullDocument: PDFExamResumePolicy.usesFullDocumentPages(
                selectedPageIndices: attempt.selectedPageIndices,
                sourcePageCount: sourcePageCount
            )
        )
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
            if !session.pendingDrawingStore.isEmpty {
                scheduleModelContextSave()
            }
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
        let pageSubmissions = try modelContext.fetchExamPageSubmissions(attemptID: attempt.id)
        try PDFExamArchiveStore.archive(
            attempt: attempt,
            drawings: drawings,
            gradeMarks: marks,
            pageSubmissions: pageSubmissions
        )
    }
}
