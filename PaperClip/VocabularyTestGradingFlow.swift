import PencilKit

extension VocabularyTestView {
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
        let submittedIndex = currentBatchIndex
        if sessionMode == .exam {
            startBatchGrading(batchIndex: submittedIndex, automaticRetry: true)
            if currentBatchIndex + 1 < batches.count {
                currentBatchIndex += 1
                currentIndex = 0
                replaceCurrentDrawing(with: PKDrawing())
            } else {
                didFinishAnswering = true
            }
        } else {
            startBatchGrading(batchIndex: submittedIndex, automaticRetry: false)
        }
    }
}
