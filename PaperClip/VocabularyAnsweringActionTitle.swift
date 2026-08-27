enum VocabularyAnsweringActionTitle {
    static func title(isExam: Bool, isLastInBatch: Bool, isLastBatch: Bool) -> String {
        guard isLastInBatch else { return "下一题" }
        guard isExam else { return "提交答卷" }
        return isLastBatch ? "提交全卷" : "提交并继续"
    }
}

enum VocabularyAnswerAdvancePolicy {
    static let undoDuration: Duration = .seconds(3)

    static func requiresConfirmation(hasInk: Bool) -> Bool {
        !hasInk
    }

    static func undoTarget(
        batchIndex: Int,
        answeredQuestionIndex: Int,
        drawingIndex: Int,
        isLastInBatch: Bool
    ) -> VocabularyAnswerAdvanceUndoTarget? {
        guard !isLastInBatch else { return nil }
        return VocabularyAnswerAdvanceUndoTarget(
            batchIndex: batchIndex,
            answeredQuestionIndex: answeredQuestionIndex,
            drawingIndex: drawingIndex
        )
    }
}

struct VocabularyAnswerAdvanceUndoTarget: Equatable {
    let batchIndex: Int
    let answeredQuestionIndex: Int
    let drawingIndex: Int

    func canRestore(
        currentBatchIndex: Int,
        currentQuestionIndex: Int,
        currentAnswerHasInk: Bool,
        storedDrawingCount: Int
    ) -> Bool {
        batchIndex == currentBatchIndex
            && currentQuestionIndex == answeredQuestionIndex + 1
            && !currentAnswerHasInk
            && drawingIndex == storedDrawingCount - 1
    }
}
