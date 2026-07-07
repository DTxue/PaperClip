import Foundation

extension DiaryEntryDetailPane {
    func batchAnalyze() {
        var pending: [KnowledgeItem] = []
        for item in entry.items where item.status == "draft" && !item.summary.isEmpty {
            pending.append(item)
        }
        guard !pending.isEmpty else { return }
        _ = batchAnalysisTaskSlot.start { taskID in
            var didChange = false
            for item in pending {
                guard isCurrentBatchAnalysisTask(taskID), !Task.isCancelled else { break }
                do {
                    let result = try await AIService.analyzeKnowledgeItem(item.summary)
                    try Task.checkCancellation()
                    guard isCurrentBatchAnalysisTask(taskID) else { break }
                    if DiaryKnowledgeAnalysisApplier.apply(result, to: item) {
                        didChange = true
                    }
                } catch is CancellationError {
                    break
                } catch {
                    guard isCurrentBatchAnalysisTask(taskID) else { break }
                    if DiaryKnowledgeAnalysisApplier.markFailed(item) {
                        didChange = true
                    }
                }
            }
            guard isCurrentBatchAnalysisTask(taskID) else { return }
            if didChange {
                do {
                    try modelContext.saveOrRollbackIfNeeded()
                } catch {
                    extractError = "解析完成，但保存失败：\(error.localizedDescription)"
                }
            }
            finishBatchAnalysisTask(taskID)
        }
    }

    func isCurrentBatchAnalysisTask(_ taskID: UUID) -> Bool {
        batchAnalysisTaskSlot.isCurrent(taskID)
    }

    func finishBatchAnalysisTask(_ taskID: UUID) {
        batchAnalysisTaskSlot.finish(taskID)
    }
}
