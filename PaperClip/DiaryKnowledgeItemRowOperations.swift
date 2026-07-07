import Foundation

extension DraftKnowledgeItemRow {
    func analyze() {
        guard commitSummaryDraft() else { return }
        cancelAnalysisTask()
        let summary = summaryDraft
        isAnalyzing = true
        analysisError = nil
        item.resetAnalysisState()

        _ = analysisTaskSlot.start { taskID in
            await runAnalysis(summary: summary, taskID: taskID)
            analysisTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func runAnalysis(summary: String, taskID: UUID) async {
        do {
            let result = try await AIService.analyzeKnowledgeItem(summary)
            try Task.checkCancellation()
            guard analysisTaskSlot.isCurrent(taskID) else { return }
            if applyAnalysis(result) {
                do {
                    try modelContext.saveOrRollbackIfNeeded()
                } catch {
                    analysisError = "解析完成，但保存失败：\(error.localizedDescription)"
                }
            }
            isAnalyzing = false
        } catch is CancellationError {
            guard analysisTaskSlot.isCurrent(taskID) else { return }
            isAnalyzing = false
        } catch {
            guard !Task.isCancelled else { return }
            guard analysisTaskSlot.isCurrent(taskID) else { return }
            if markAnalysisFailed() {
                do {
                    try modelContext.saveOrRollbackIfNeeded()
                } catch {
                    analysisError = "解析失败，且失败状态保存失败：\(error.localizedDescription)"
                }
            }
            isAnalyzing = false
            if analysisError == nil {
                analysisError = error.localizedDescription
            }
        }
    }

    func cancelAnalysisTask() {
        analysisTaskSlot.cancel()
        isAnalyzing = false
    }

    func applyAnalysis(_ result: KnowledgeAnalysis) -> Bool {
        item.applyAnalysis(result)
    }

    func markAnalysisFailed() -> Bool {
        item.markAnalysisFailed()
    }

    @discardableResult
    func commitSummaryDraft() -> Bool {
        let trimmed = summaryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard item.summary != trimmed else { return true }
        item.summary = trimmed
        item.updatedAt = Date()
        do {
            try modelContext.saveOrRollbackIfNeeded()
            return true
        } catch {
            summaryDraft = item.summary
            alert = AppAlert(title: "无法保存知识点摘要", error: error)
            return false
        }
    }

    func deleteItem() {
        cancelAnalysisTask()
        modelContext.delete(item)
        do {
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            alert = AppAlert(title: "无法删除知识点", error: error)
        }
    }
}
