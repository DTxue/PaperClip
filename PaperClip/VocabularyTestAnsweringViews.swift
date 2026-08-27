import SwiftUI
import PencilKit

extension VocabularyTestView {
    @ViewBuilder
    func regularSessionView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        if let batch = batches.first {
            switch batch.status {
            case .grading, .retrying:
                VocabularyTestGradingView(message: handwritingTestKind.gradingMessage)
            case .graded:
                VocabularyTestResultsView(
                    title: sessionMode == .debug ? "调试完成" : handwritingTestKind.completionTitle,
                    handwritingTestKind: handwritingTestKind,
                    questions: snapshot.gradedQuestions,
                    enlargedImage: $enlargedImage
                )
            case .failed:
                VocabularyTestErrorView(message: batch.errorMessage ?? "请稍后重试。") {
                    startBatchGrading(batchIndex: 0, automaticRetry: false)
                }
            case .answering:
                answeringView(snapshot)
            }
        } else {
            setupView(snapshot)
        }
    }

    func answeringView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        VocabularyTestAnsweringContentView(
            sessionMode: sessionMode,
            handwritingTestKind: handwritingTestKind,
            snapshot: snapshot,
            batches: batches,
            activeBatch: activeBatch,
            currentBatchIndex: currentBatchIndex,
            currentIndex: currentIndex,
            currentCard: currentCard,
            currentDrawing: $currentDrawing,
            answerCanvasSession: answerCanvasSession,
            currentDrawingReloadToken: currentDrawingReloadToken,
            didFinishAnswering: didFinishAnswering,
            onDrawingChanged: handleAnswerDrawingChanged
        )
    }

    var currentCard: VocabularyCard? {
        guard let batch = activeBatch, batch.cards.indices.contains(currentIndex) else { return nil }
        return batch.cards[currentIndex]
    }

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

    func presentAnswerAdvanceUndo(_ target: VocabularyAnswerAdvanceUndoTarget) {
        answerAdvanceUndoTarget = target
        answerAdvanceUndoDismissAction.schedule(after: VocabularyAnswerAdvancePolicy.undoDuration) {
            answerAdvanceUndoTarget = nil
        }
    }

}
