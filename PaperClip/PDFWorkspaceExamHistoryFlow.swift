import SwiftData
import SwiftUI

extension PDFWorkspaceView {
    func refreshExamSummary() {
        do {
            try modelContext.repairExamAttemptLinks(for: document)
            let latestAttempt = try modelContext.fetchLatestExamAttempt(
                document: document,
                propertiesToFetch: ExamAttemptHistoryRowData.propertiesToFetch
            )
            let latest = try latestAttempt.map { try examHistoryRow(for: $0) }
            let sourcePageCount = PDFPageDocumentReader.pageCount(in: document.localFileURL)
            let currentAttempt = try modelContext.fetchResumableFullDocumentExamAttempt(
                document: document,
                sourcePageCount: sourcePageCount,
                propertiesToFetch: ExamAttemptHistoryRowData.propertiesToFetch
            )
            session.currentAttemptSummary = try currentAttempt.map { try examHistoryRow(for: $0) }
            let count = try modelContext.fetchExamAttemptCount(document: document)
            applyExamHistoryState(ExamAttemptHistoryState(
                summaryLatestAttempt: latest,
                attemptCount: count,
                cachedAttempts: session.examHistoryAttempts
            ))
        } catch {
            session.latestAttempt = nil
            session.currentAttemptSummary = nil
            session.attemptCount = 0
            session.alert = AppAlert(title: "无法读取考试记录", error: error)
        }
    }

    func refreshExamHistory() {
        do {
            try modelContext.repairExamAttemptLinks(for: document)
            let attempts = try modelContext.fetchExamAttempts(
                document: document,
                propertiesToFetch: ExamAttemptHistoryRowData.propertiesToFetch
            )
            let rows = try attempts.map { try examHistoryRow(for: $0) }
            applyExamHistoryState(ExamAttemptHistoryState(fetchedAttempts: rows))
        } catch {
            session.examHistoryAttempts = []
            session.alert = AppAlert(title: "无法读取考试记录", error: error)
        }
    }

    private func examHistoryRow(for attempt: ExamAttempt) throws -> ExamAttemptHistoryRowData {
        let submissions = try modelContext.fetchExamPageSubmissions(
            attemptID: attempt.id,
            propertiesToFetch: ExamPageSubmission.workspacePropertiesToFetch
        )
        return try ExamAttemptHistoryRowData(
            attempt: attempt,
            questionMetrics: examQuestionMetrics(attemptID: attempt.id),
            pageProgress: submissions.isEmpty ? nil : PDFExamPageProgress(
                pageIndices: attempt.selectedPageIndices,
                submissions: submissions
            )
        )
    }

    private func examQuestionMetrics(attemptID: UUID) throws -> ExamAttemptQuestionMetrics {
        let marks = try modelContext.fetchExamGradeMarks(
            attemptID: attemptID,
            propertiesToFetch: [
                \.attemptId,
                \.isCorrect
            ]
        )
        return marks.reduce(into: ExamAttemptQuestionMetrics()) { metrics, mark in
            metrics.add(isCorrect: mark.isCorrect)
        }
    }

    func noteExamAttemptInserted(_ attempt: ExamAttempt) {
        session.noteExamAttemptInserted(attempt)
    }

    func noteExamAttemptUpdated(_ attempt: ExamAttempt) {
        session.noteExamAttemptUpdated(attempt)
    }

    func currentExamHistoryState() -> ExamAttemptHistoryState {
        session.currentExamHistoryState()
    }

    func applyExamHistoryState(_ state: ExamAttemptHistoryState) {
        session.applyExamHistoryState(state)
    }

    func openExamHistory() {
        refreshExamHistory()
        session.isExamHistoryPresented = true
    }

    func deleteInProgressExamAttempt(id attemptID: UUID) {
        let deletesActiveAttempt = session.activeAttempt?.id == attemptID
        if deletesActiveAttempt {
            session.pendingSaveAction.cancel()
        }

        let fileURLsToDelete: [URL]
        do {
            fileURLsToDelete = try PDFArtifactDeletionTransaction.deleteInProgressExamAttempt(
                id: attemptID,
                in: modelContext
            )
        } catch {
            if deletesActiveAttempt {
                // 删除未完成时 attempt 仍然有效，保留并重新安排 pending 笔迹保存。
                scheduleModelContextSave()
            }
            session.alert = AppAlert(title: "无法删除考试记录", error: error)
            return
        }

        if deletesActiveAttempt {
            session.resetAfterExamExit()
        }
        refreshExamHistory()

        do {
            try StorageService.deleteFiles(at: fileURLsToDelete)
        } catch {
            session.alert = AppAlert(title: "考试记录已删除，缓存清理失败", error: error)
        }
    }
}
