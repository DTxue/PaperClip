import Foundation

extension VocabularyTestView {
    @discardableResult
    func saveDraft() -> Bool {
        guard sessionMode == .exam, !batches.isEmpty else { return true }
        draftSaveAction.cancel()
        let batchSnapshots = VocabularyTestDraftSnapshotBuilder.batchSnapshots(
            from: batches,
            drawingDataCache: draftDrawingDataCache
        )
        let batchSize = min(questionCount, VocabularyTestBatchBuilder.maximumQuestionCount(in: batches))
        let payload = VocabularyTestDraftSavePayload(
            batchSize: batchSize,
            currentBatchIndex: currentBatchIndex,
            currentQuestionIndex: currentIndex,
            currentDrawingData: currentDrawingDataForDraft(),
            didFinishAnswering: didFinishAnswering,
            startedAt: startedAt,
            batches: batchSnapshots
        )

        if let draft = latestDraft {
            let didChange = draft.update(payload: payload)
            guard didChange else { return true }
        } else {
            let draft = VocabularyTestDraft(
                deckID: deck.id,
                mode: VocabularyTestMode.exam.rawValue,
                payload: payload
            )
            modelContext.insert(draft)
            latestDraft = draft
        }
        do {
            try modelContext.saveOrRollbackIfNeeded()
            return true
        } catch {
            refreshLatestDraft()
            alert = AppAlert(title: "无法保存考试草稿", error: error)
            return false
        }
    }

    func scheduleDraftSave() {
        guard sessionMode == .exam, !batches.isEmpty else { return }
        draftSaveAction.schedule(after: .milliseconds(700)) {
            saveDraft()
        }
    }
}
