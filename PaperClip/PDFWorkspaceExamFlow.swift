import SwiftUI
import SwiftData

extension PDFWorkspaceView {
    func startExam(with selectedPageIndices: [Int]) {
        guard prepareForExamAttemptActivation() else { return }
        do {
            let attempt = try PDFExamAttemptStore.createAttempt(
                document: document,
                selectedPageIndices: selectedPageIndices,
                in: modelContext
            )
            session.isPageSelectionPresented = false
            noteExamAttemptInserted(attempt)
            activateAttempt(attempt)
        } catch {
            session.alert = AppAlert(title: "无法开始答题", error: error)
        }
    }

    func activateAttempt(_ attempt: ExamAttempt) {
        guard prepareForExamAttemptActivation() else { return }
        do {
            let url = try ensureExamPDFCache(for: attempt)
            applyActiveExamAttempt(attempt, pdfURL: url)
            loadExamAnswers(for: attempt)
            refreshGradeMarks(for: attempt)
        } catch {
            session.alert = AppAlert(title: "无法打开考试记录", error: error)
        }
    }

    func activateAttempt(id attemptID: UUID) {
        do {
            guard let attempt = try modelContext.fetchExamAttempt(id: attemptID) else {
                session.alert = AppAlert(title: "无法打开考试记录", message: "该考试记录不存在或已被删除。")
                return
            }
            activateAttempt(attempt)
        } catch {
            session.alert = AppAlert(title: "无法打开考试记录", error: error)
        }
    }

    func ensureExamPDFCache(for attempt: ExamAttempt) throws -> URL {
        let result = try PDFExamAttemptStore.ensurePDFCache(
            for: attempt,
            sourceURL: document.localFileURL,
            in: modelContext
        )
        if result.didUpdateAttempt {
            noteExamAttemptUpdated(attempt)
        }
        return result.url
    }

    func loadExamAnswers(for attempt: ExamAttempt) {
        do {
            let result = try answerLayerStore.loadLatestLayers(attemptID: attempt.id)
            applyLoadedExamAnswers(result)
        } catch {
            clearLoadedExamAnswers()
            session.alert = AppAlert(title: "无法读取答题内容", error: error)
        }
    }

    func refreshGradeMarks(for attempt: ExamAttempt) {
        let attemptID = attempt.id
        do {
            session.activeGradeMarks = try modelContext.fetchExamGradeMarks(
                attemptID: attemptID,
                propertiesToFetch: ExamGradeMark.workspacePropertiesToFetch
            )
        } catch {
            session.activeGradeMarks = []
            session.alert = AppAlert(title: "无法读取批改标记", error: error)
        }
    }
}
