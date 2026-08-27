extension VocabularyTestView {
    func restoreDraft(_ draft: VocabularyTestDraft) {
        dismissAnswerAdvanceUndo()
        isConfirmingEmptyAnswer = false
        fetchSessionData()
        restartGradingSession()
        guard let restoredDraft = VocabularyTestDraftRestorer.restore(draft: draft, cards: allCards) else {
            deleteDraft(draft)
            return
        }
        selectedMode = .exam
        sessionMode = .exam
        questionCount = restoredDraft.questionCount
        batches = restoredDraft.batches
        draftDrawingDataCache = restoredDraft.drawingDataCache
        currentBatchIndex = restoredDraft.currentBatchIndex
        currentIndex = restoredDraft.currentQuestionIndex
        replaceCurrentDrawing(with: restoredDraft.currentDrawing)
        startedAt = draft.startedAt
        didRecordSession = false
        didFinishAnswering = draft.didFinishAnswering
        finishSessionIfReady()
        saveDraft()
    }
}
