import Foundation

extension DiaryEntryDetailPane {
    func startDrafting() {
        _ = deleteKnowledgeItems(where: { _ in true })

        phase = .drafting

        restartExtractionTask {
            try await extractKnowledge(from: entry.learned, source: "learned")
            try await extractKnowledge(from: entry.confused, source: "confused")
        }
    }

    func reExtract(source: String) {
        let text = source == "learned" ? entry.learned : entry.confused
        guard !text.isEmpty else { return }

        _ = deleteKnowledgeItems(where: { $0.source == source })

        restartExtractionTask {
            try await extractKnowledge(from: text, source: source)
        }
    }

    func restartExtractionTask(
        _ operation: @escaping @MainActor () async throws -> Void
    ) {
        extractError = nil

        _ = extractionTaskSlot.start { taskID in
            do {
                try await operation()
                guard isCurrentExtractionTask(taskID) else { return }
                guard saveDiaryChanges(alertTitle: "无法保存知识点草稿") else {
                    finishExtractionTask(taskID)
                    return
                }
                finishExtractionTask(taskID)
            } catch is CancellationError {
                guard isCurrentExtractionTask(taskID) else { return }
                finishExtractionTask(taskID)
            } catch {
                guard isCurrentExtractionTask(taskID) else { return }
                savePendingExtractionChanges()
                if extractError == nil {
                    extractError = error.localizedDescription
                }
                finishExtractionTask(taskID)
            }
        }
    }

    func isCurrentExtractionTask(_ taskID: UUID) -> Bool {
        extractionTaskSlot.isCurrent(taskID)
    }

    func finishExtractionTask(_ taskID: UUID) {
        extractionTaskSlot.finish(taskID)
    }

    @MainActor
    func extractKnowledge(from text: String, source: String) async throws {
        guard !text.isEmpty else { return }
        let items = try await AIService.extractKnowledgeItems(from: text, source: source)
        try Task.checkCancellation()
        guard !items.isEmpty else { return }
        for extracted in items {
            let item = KnowledgeItem(summary: extracted.text, source: source, entry: entry)
            item.changeNote = extracted.change ?? ""
            modelContext.insert(item)
        }
    }

    func savePendingExtractionChanges() {
        guard modelContext.hasChanges else { return }
        do {
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            extractError = "提取失败，且知识点状态保存失败：\(error.localizedDescription)"
        }
    }
}
