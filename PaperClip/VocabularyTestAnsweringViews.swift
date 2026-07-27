import SwiftUI
import PencilKit

extension VocabularyTestView {
    @ViewBuilder
    func regularSessionView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        if let batch = batches.first {
            switch batch.status {
            case .grading, .retrying:
                VocabularyTestGradingView(message: "AI 正在批改中…")
            case .graded:
                VocabularyTestResultsView(
                    title: sessionMode == .debug ? "调试完成" : "测验完成",
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
            snapshot: snapshot,
            batches: batches,
            activeBatch: activeBatch,
            currentBatchIndex: currentBatchIndex,
            currentIndex: currentIndex,
            currentCard: currentCard,
            currentDrawing: $currentDrawing,
            currentDrawingReloadToken: currentDrawingReloadToken,
            didFinishAnswering: didFinishAnswering,
            onAdvance: advanceQuestion,
            onDrawingChanged: scheduleDraftSave
        )
    }

    var currentCard: VocabularyCard? {
        guard let batch = activeBatch, batch.cards.indices.contains(currentIndex) else { return nil }
        return batch.cards[currentIndex]
    }

}
