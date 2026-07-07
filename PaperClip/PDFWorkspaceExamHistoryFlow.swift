import SwiftData
import SwiftUI

extension PDFWorkspaceView {
    func refreshExamSummary() {
        do {
            try modelContext.repairExamAttemptLinks(for: document)
            let latest = try modelContext.fetchLatestExamAttempt(
                document: document,
                propertiesToFetch: ExamAttemptHistoryRowData.propertiesToFetch
            ).map(ExamAttemptHistoryRowData.init)
            let count = try modelContext.fetchExamAttemptCount(document: document)
            applyExamHistoryState(ExamAttemptHistoryState(
                summaryLatestAttempt: latest,
                attemptCount: count,
                cachedAttempts: session.examHistoryAttempts
            ))
        } catch {
            session.latestAttempt = nil
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
            ).map(ExamAttemptHistoryRowData.init)
            applyExamHistoryState(ExamAttemptHistoryState(fetchedAttempts: attempts))
        } catch {
            session.examHistoryAttempts = []
            session.alert = AppAlert(title: "无法读取考试记录", error: error)
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
}
