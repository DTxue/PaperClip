import PencilKit

extension VocabularyTestView {
    func finishTestEarly() {
        guard batches.indices.contains(currentBatchIndex),
              batches[currentBatchIndex].status == .answering else { return }

        dismissAnswerAdvanceUndo()
        isConfirmingEmptyAnswer = false
        isConfirmingTestExit = false

        let submittedDrawing = answerCanvasSession.snapshot(fallback: currentDrawing)
        currentDrawing = submittedDrawing
        let drawingIndex = batches[currentBatchIndex].drawings.count
        draftDrawingDataCache.set(
            DrawingDataSupport.data(from: submittedDrawing),
            for: VocabularyDraftDrawingKey(
                batchID: batches[currentBatchIndex].id,
                drawingIndex: drawingIndex
            )
        )
        batches[currentBatchIndex].drawings = VocabularyTestEarlyFinishPolicy.completedAnswers(
            submittedAnswers: batches[currentBatchIndex].drawings,
            currentAnswer: submittedDrawing,
            totalQuestionCount: batches[currentBatchIndex].cards.count,
            blankAnswer: PKDrawing()
        )
        submitCurrentBatch()
    }

    func advanceQuestion() {
        guard batches.indices.contains(currentBatchIndex) else { return }
        dismissAnswerAdvanceUndo()
        isConfirmingEmptyAnswer = false
        let submittedDrawing = answerCanvasSession.snapshot(fallback: currentDrawing)
        currentDrawing = submittedDrawing
        let drawingIndex = batches[currentBatchIndex].drawings.count
        let isLastInBatch = currentIndex + 1 == batches[currentBatchIndex].cards.count
        let undoTarget = VocabularyAnswerAdvancePolicy.undoTarget(
            batchIndex: currentBatchIndex,
            answeredQuestionIndex: currentIndex,
            drawingIndex: drawingIndex,
            isLastInBatch: isLastInBatch
        )
        let currentDrawingData = DrawingDataSupport.data(from: submittedDrawing)
        batches[currentBatchIndex].drawings.append(submittedDrawing)
        draftDrawingDataCache.set(
            currentDrawingData,
            for: VocabularyDraftDrawingKey(
                batchID: batches[currentBatchIndex].id,
                drawingIndex: drawingIndex
            )
        )
        replaceCurrentDrawing(with: PKDrawing())
        if currentIndex + 1 < batches[currentBatchIndex].cards.count {
            currentIndex += 1
            if let undoTarget {
                presentAnswerAdvanceUndo(undoTarget)
            }
        } else {
            submitCurrentBatch()
        }
    }

    func submitCurrentBatch() {
        startBatchGrading(batchIndex: currentBatchIndex)
    }
}
