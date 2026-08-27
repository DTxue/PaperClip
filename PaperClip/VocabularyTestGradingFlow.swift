import PencilKit

extension VocabularyTestView {
    func requestAdvanceQuestion() {
        let drawing = answerCanvasSession.snapshot(fallback: currentDrawing)
        currentDrawing = drawing
        guard !VocabularyAnswerAdvancePolicy.requiresConfirmation(
            hasInk: DrawingDataSupport.hasInk(drawing)
        ) else {
            isConfirmingEmptyAnswer = true
            return
        }
        advanceQuestion()
    }

    func handleAnswerDrawingChanged() {
        scheduleDraftSave()
        guard answerAdvanceUndoTarget != nil else { return }
        let drawing = answerCanvasSession.snapshot(fallback: currentDrawing)
        guard DrawingDataSupport.hasInk(drawing) else { return }
        currentDrawing = drawing
        dismissAnswerAdvanceUndo()
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
            saveDraft()
            if let undoTarget {
                presentAnswerAdvanceUndo(undoTarget)
            }
        } else {
            submitCurrentBatch()
        }
    }

    func undoLastAnswerAdvance() {
        guard let target = answerAdvanceUndoTarget,
              batches.indices.contains(target.batchIndex),
              batches[target.batchIndex].status == .answering else {
            dismissAnswerAdvanceUndo()
            return
        }

        let currentAnswer = answerCanvasSession.snapshot(fallback: currentDrawing)
        currentDrawing = currentAnswer
        guard target.canRestore(
            currentBatchIndex: currentBatchIndex,
            currentQuestionIndex: currentIndex,
            currentAnswerHasInk: DrawingDataSupport.hasInk(currentAnswer),
            storedDrawingCount: batches[target.batchIndex].drawings.count
        ) else {
            dismissAnswerAdvanceUndo()
            return
        }

        let restoredDrawing = batches[target.batchIndex].drawings.removeLast()
        let cacheKey = VocabularyDraftDrawingKey(
            batchID: batches[target.batchIndex].id,
            drawingIndex: target.drawingIndex
        )
        draftDrawingDataCache.removeValue(for: cacheKey)
        dismissAnswerAdvanceUndo()
        currentIndex = target.answeredQuestionIndex
        replaceCurrentDrawing(with: restoredDrawing)
        saveDraft()
    }

    func dismissAnswerAdvanceUndo() {
        answerAdvanceUndoDismissAction.cancel()
        answerAdvanceUndoTarget = nil
    }

    private func presentAnswerAdvanceUndo(_ target: VocabularyAnswerAdvanceUndoTarget) {
        answerAdvanceUndoTarget = target
        answerAdvanceUndoDismissAction.schedule(after: VocabularyAnswerAdvancePolicy.undoDuration) {
            answerAdvanceUndoTarget = nil
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
