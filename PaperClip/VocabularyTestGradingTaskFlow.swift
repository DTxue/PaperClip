import Foundation

extension VocabularyTestView {
    func startBatchGrading(batchIndex: Int, automaticRetry: Bool) {
        guard batches.indices.contains(batchIndex) else { return }
        let batchID = batches[batchIndex].id
        let taskContext = gradingTaskStore.prepareTask(batchID: batchID)
        batches[batchIndex].status = .grading
        batches[batchIndex].errorMessage = nil
        batches[batchIndex].result = nil
        batches[batchIndex].renderedImages = []
        batches[batchIndex].gradingAttempts = 0
        saveDraft()

        let task = VocabularyBatchGradingRunner.makeTask(
            request: VocabularyBatchGradingRequest(
                batchIndex: batchIndex,
                batchID: batchID,
                context: taskContext,
                kind: handwritingTestKind,
                cards: batches[batchIndex].cards.map {
                    VocabularyHandwritingGradingCard(
                        term: $0.term,
                        definition: $0.definition,
                        englishDefinition: $0.englishDefinition
                    )
                },
                drawings: batches[batchIndex].drawings,
                automaticRetry: automaticRetry
            ),
            callbacks: VocabularyBatchGradingCallbacks(
                isCurrent: { context, batchID, batchIndex in
                    isCurrentGradingTask(
                        sessionID: context.sessionID,
                        taskID: context.taskID,
                        batchID: batchID,
                        batchIndex: batchIndex
                    )
                },
                markAttempt: { batchIndex, attempt, status in
                    batches[batchIndex].status = status
                    batches[batchIndex].gradingAttempts = attempt
                    saveDraft()
                },
                finishSuccess: { batchIndex, images, result, context in
                    batches[batchIndex].renderedImages = images
                    batches[batchIndex].result = result
                    batches[batchIndex].status = .graded
                    batches[batchIndex].errorMessage = nil
                    saveDraft()
                    finishSessionIfReady()
                    clearGradingTask(
                        batchID: batches[batchIndex].id,
                        taskID: context.taskID
                    )
                },
                finishFailure: { batchIndex, images, errorMessage, context in
                    batches[batchIndex].renderedImages = images
                    batches[batchIndex].status = .failed
                    batches[batchIndex].errorMessage = errorMessage
                    saveDraft()
                    clearGradingTask(
                        batchID: batches[batchIndex].id,
                        taskID: context.taskID
                    )
                },
                clearTask: clearGradingTask
            )
        )
        gradingTaskStore.setTask(task, batchID: batchID, taskID: taskContext.taskID)
    }

    func restartGradingSession() {
        gradingTaskStore.restart()
    }

    func cancelGradingTasks() {
        gradingTaskStore.cancelAll()
    }

    func isCurrentGradingTask(
        sessionID: UUID,
        taskID: UUID,
        batchID: Int,
        batchIndex: Int
    ) -> Bool {
        gradingTaskStore.isCurrent(
            sessionID: sessionID,
            taskID: taskID,
            batchID: batchID
        )
            && batches.indices.contains(batchIndex)
            && batches[batchIndex].id == batchID
    }

    func clearGradingTask(batchID: Int, taskID: UUID) {
        gradingTaskStore.clear(batchID: batchID, taskID: taskID)
    }

    func retryFailedBatches() {
        for index in VocabularyTestBatchProjection.failedBatchIndices(in: batches) {
            startBatchGrading(batchIndex: index, automaticRetry: false)
        }
    }
}
