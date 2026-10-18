import SwiftUI
import PencilKit

extension VocabularyTestView {
    @ViewBuilder
    func regularSessionView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        if let batch = batches.first {
            switch batch.status {
            case .grading:
                VocabularyTestGradingView(
                    message: deck.kind == .dictationChinese
                        ? usesLocalChineseRecognition ? "正在本机识别中文笔迹…" : "AI 正在识别中文笔迹…"
                        : handwritingTestKind.gradingMessage
                )
            case .graded:
                VocabularyTestResultsView(
                    title: sessionMode == .debug ? "调试完成" : handwritingTestKind.completionTitle,
                    handwritingTestKind: handwritingTestKind,
                    questions: snapshot.gradedQuestions,
                    enlargedImage: $enlargedImage
                )
            case .failed:
                VocabularyTestErrorView(message: batch.errorMessage ?? "请稍后重试。") {
                    startBatchGrading(batchIndex: 0)
                }
            case .answering:
                answeringView()
            }
        } else {
            setupView(snapshot)
        }
    }

    func answeringView() -> some View {
        VocabularyTestAnsweringContentView(
            handwritingTestKind: handwritingTestKind,
            usesChineseCharacterByCharacterRecognition: usesChineseCharacterByCharacterRecognition,
            activeBatch: activeBatch,
            currentIndex: currentIndex,
            currentCard: currentCard,
            currentDrawing: $currentDrawing,
            answerCanvasSession: answerCanvasSession,
            currentDrawingReloadToken: currentDrawingReloadToken
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
