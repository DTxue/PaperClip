import SwiftData
import PencilKit

extension PDFWorkspaceView {
    var answerLayerStore: PDFAnswerLayerStore {
        PDFAnswerLayerStore(modelContext: modelContext)
    }

    func saveDrawing(pageIndex: Int, drawing: PKDrawing) {
        guard let attempt = session.activeAttempt,
              attempt.status == ExamAttemptStatus.inProgress.rawValue,
              session.writablePageIndices()?.contains(pageIndex) ?? true
        else { return }
        session.pendingDrawingStore.set(drawing, for: pageIndex)
        scheduleModelContextSave()
    }

    @discardableResult
    func flushPendingDrawings() -> Bool {
        do {
            return try flushPendingDrawingsThrowing()
        } catch {
            session.alert = AppAlert(title: "保存答题失败", error: error)
            return false
        }
    }

    @discardableResult
    func flushPendingDrawingsThrowing() throws -> Bool {
        guard let attempt = session.activeAttempt else {
            session.pendingDrawingStore.removeAll()
            return false
        }
        let pendingDrawingData = session.pendingDrawingStore.snapshotDrawingData()
        guard !pendingDrawingData.isEmpty else { return false }

        let result = try answerLayerStore.savePendingDrawingData(
            sourceDocumentID: document.id,
            attempt: attempt,
            pendingDrawingDataByPage: pendingDrawingData,
            currentDrawingDataByPage: session.drawings,
            currentLayersByPage: session.examHandwritingByPage
        )
        session.drawings = result.drawingDataByPage
        session.examHandwritingByPage = result.layersByPage
        session.pendingDrawingStore.removePages(result.completedPageIndices)
        return result.didSave
    }

    /// 清除当前会话的所有手写内容，不影响其他会话。
    func clearAllAnswers() {
        guard let attempt = session.activeAttempt,
              attempt.status == ExamAttemptStatus.inProgress.rawValue
        else { return }
        if let pageIndex = session.writablePageIndices()?.first {
            clearCurrentPageAnswer(attempt: attempt, pageIndex: pageIndex)
            return
        }
        do {
            try answerLayerStore.clearAnswers(for: attempt)
        } catch {
            session.alert = AppAlert(title: "无法清除答题内容", error: error)
            return
        }
        session.drawings.removeAll()
        session.pendingDrawingStore.removeAll()
        session.examHandwritingByPage.removeAll()
        session.clearAnswersToken += 1
        session.pendingSaveAction.cancel()
        archiveActiveExamAttemptBestEffort()
    }

    private func clearCurrentPageAnswer(attempt: ExamAttempt, pageIndex: Int) {
        do {
            try answerLayerStore.clearAnswer(for: attempt, pageIndex: pageIndex)
        } catch {
            session.alert = AppAlert(title: "无法清除当前页答案", error: error)
            return
        }
        session.drawings[pageIndex] = nil
        session.pendingDrawingStore.removePages(Set([pageIndex]))
        session.examHandwritingByPage[pageIndex] = nil
        session.reloadDrawingsToken += 1
        session.pendingSaveAction.cancel()
        archiveActiveExamAttemptBestEffort()
    }

    func persistModelContext() {
        do {
            let didSave = try persistModelContextThrowing()
            if didSave {
                archiveActiveExamAttemptBestEffort()
            }
        } catch {
            session.alert = AppAlert(title: "保存答题失败", error: error)
        }
    }

    @discardableResult
    func persistModelContextThrowing() throws -> Bool {
        let didFlushDrawingChanges = try flushPendingDrawingsThrowing()
        guard didFlushDrawingChanges || modelContext.hasChanges else { return false }
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }

    func scheduleModelContextSave() {
        session.pendingSaveAction.schedule(after: .milliseconds(250)) {
            persistModelContext()
        }
    }

    func canvasSizesDidChange(_ sizes: [Int: CGSize]) {
        guard session.canvasSizes != sizes else { return }
        session.canvasSizes = sizes
    }
}
