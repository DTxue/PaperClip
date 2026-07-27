import PencilKit

extension VocabularyTestView {
    func advanceQuestion() {
        guard batches.indices.contains(currentBatchIndex) else { return }
        let submittedDrawing = answerCanvasSession.snapshot(fallback: currentDrawing)
        currentDrawing = submittedDrawing
        let drawingIndex = batches[currentBatchIndex].drawings.count
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
            saveDraft()
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
                saveDraft()
            } else {
                didFinishAnswering = true
                saveDraft()
            }
        } else {
            startBatchGrading(batchIndex: submittedIndex, automaticRetry: false)
        }
    }
}
