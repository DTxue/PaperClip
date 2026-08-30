import SwiftUI
import SwiftData

extension PDFWorkspaceView {
    func startOrResumeFullExam() {
        guard prepareForExamAttemptActivation() else { return }
        do {
            let sourcePageCount = PDFPageDocumentReader.pageCount(in: document.localFileURL)
            let existingAttempt = try modelContext.fetchResumableFullDocumentExamAttempt(
                document: document,
                sourcePageCount: sourcePageCount
            )
            let attempt = try PDFExamAttemptStore.startOrResumeFullDocumentExam(
                document: document,
                in: modelContext
            )
            if existingAttempt == nil {
                noteExamAttemptInserted(attempt)
            }
            session.currentAttemptSummary = ExamAttemptHistoryRowData(attempt: attempt)
            if existingAttempt == nil {
                activateAttempt(attempt, requestedPageIndex: attempt.selectedPageIndices.first)
            } else {
                try presentResumePageSelection(for: attempt)
            }
        } catch {
            session.alert = AppAlert(title: "无法开始答题", error: error)
        }
    }

    func startExam(with selectedPageIndices: [Int]) {
        guard prepareForExamAttemptActivation() else { return }
        do {
            let attempt = try PDFExamAttemptStore.createAttempt(
                document: document,
                selectedPageIndices: selectedPageIndices,
                in: modelContext
            )
            noteExamAttemptInserted(attempt)
            activateAttempt(attempt)
        } catch {
            session.alert = AppAlert(title: "无法开始答题", error: error)
        }
    }

    func activateAttempt(_ attempt: ExamAttempt, requestedPageIndex: Int? = nil) {
        guard prepareForExamAttemptActivation() else { return }
        do {
            let url = try ensureExamPDFCache(for: attempt)
            let answers = try answerLayerStore.loadLatestLayers(attemptID: attempt.id)
            let gradeMarks = try modelContext.fetchExamGradeMarks(
                attemptID: attempt.id,
                propertiesToFetch: ExamGradeMark.workspacePropertiesToFetch
            )
            let pageSubmissions = try modelContext.fetchExamPageSubmissions(
                attemptID: attempt.id,
                propertiesToFetch: ExamPageSubmission.workspacePropertiesToFetch
            )
            applyActiveExamAttempt(attempt, pdfURL: url)
            applyLoadedExamAnswers(answers)
            session.applyLoadedPageSubmissions(pageSubmissions)
            session.activeGradeMarks = gradeMarks
            let pageIndex = requestedPageIndex ?? resumeDecision(
                for: attempt,
                submissions: pageSubmissions,
                answerPageIndices: Set(answers.latest.keys)
            )?.target.pageIndex
            if let pageIndex {
                session.navigateToExamPage(pageIndex)
            }
        } catch {
            session.alert = AppAlert(title: "无法打开考试记录", error: error)
        }
    }

    func activateAttempt(id attemptID: UUID, requestedPageIndex: Int? = nil) {
        do {
            guard let attempt = try modelContext.fetchExamAttempt(id: attemptID) else {
                session.alert = AppAlert(title: "无法打开考试记录", message: "该考试记录不存在或已被删除。")
                return
            }
            activateAttempt(attempt, requestedPageIndex: requestedPageIndex)
        } catch {
            session.alert = AppAlert(title: "无法打开考试记录", error: error)
        }
    }

    func continueExam(id attemptID: UUID) {
        guard prepareForExamAttemptActivation() else { return }
        do {
            guard let attempt = try modelContext.fetchExamAttempt(id: attemptID) else {
                session.alert = AppAlert(title: "无法继续考试", message: "该考试记录不存在或已被删除。")
                return
            }
            try presentResumePageSelection(for: attempt)
        } catch {
            session.alert = AppAlert(title: "无法继续考试", error: error)
        }
    }

    private func presentResumePageSelection(for attempt: ExamAttempt) throws {
        let url = try ensureExamPDFCache(for: attempt)
        let pageSubmissions = try modelContext.fetchExamPageSubmissions(
            attemptID: attempt.id,
            propertiesToFetch: ExamPageSubmission.workspacePropertiesToFetch
        )
        let answers = try answerLayerStore.loadLatestLayers(attemptID: attempt.id)
        guard let decision = resumeDecision(
            for: attempt,
            submissions: pageSubmissions,
            answerPageIndices: Set(answers.latest.keys)
        ) else {
            activateAttempt(attempt)
            return
        }
        guard decision.target != .roundCompleted else {
            activateAttempt(attempt)
            return
        }
        session.examPageSelectionContext = PDFExamPageSelectionContext(
            attemptID: attempt.id,
            documentURL: url,
            decision: decision
        )
    }

    private func resumeDecision(
        for attempt: ExamAttempt,
        submissions: [ExamPageSubmission],
        answerPageIndices: Set<Int>
    ) -> PDFExamResumeDecision? {
        let sourcePageCount = PDFPageDocumentReader.pageCount(in: document.localFileURL)
        guard PDFExamResumePolicy.usesFullDocumentPages(
            selectedPageIndices: attempt.selectedPageIndices,
            sourcePageCount: sourcePageCount
        ) else { return nil }
        return PDFExamResumePolicy.decide(
            pageIndices: attempt.selectedPageIndices,
            submissions: submissions,
            pagesWithAnswers: answerPageIndices
        )
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
