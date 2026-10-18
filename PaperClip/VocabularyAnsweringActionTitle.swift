enum VocabularyAnsweringActionTitle {
    static func title(isLastInBatch: Bool) -> String {
        isLastInBatch ? "提交答卷" : "下一题"
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

enum VocabularyTestEarlyFinishPolicy {
    static func completedAnswers<Answer>(
        submittedAnswers: [Answer],
        currentAnswer: Answer,
        totalQuestionCount: Int,
        blankAnswer: @autoclosure () -> Answer
    ) -> [Answer] {
        guard totalQuestionCount > 0 else { return [] }

        var answers = Array(submittedAnswers.prefix(totalQuestionCount - 1))
        answers.append(currentAnswer)
        while answers.count < totalQuestionCount {
            answers.append(blankAnswer())
        }
        return answers
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
