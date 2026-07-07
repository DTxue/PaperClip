import Foundation

extension AIAnalysisView {
    @MainActor
    func startRecognition() {
        _ = operationTaskSlot.start { taskID in
            await recognize(taskID: taskID)
            operationTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func startSolving(using model: AIAnswerModel) {
        _ = operationTaskSlot.start { taskID in
            await solve(using: model, taskID: taskID)
            operationTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func retryFailedOperation() {
        switch failedOperation {
        case .recognition:
            startRecognition()
        case .solution:
            startSolving(using: selectedModel)
        }
    }

    @MainActor
    func cancelOperation() {
        operationTaskSlot.cancel()
    }

    @MainActor
    func recognize(taskID: UUID) async {
        phase = .recognizing
        failedOperation = .recognition
        do {
            let value = try await AIService.recognize(image: image)
            try Task.checkCancellation()
            guard operationTaskSlot.isCurrent(taskID) else { return }
            recognition = value
            confirmedQuestion = value.recognizedQuestion
            solution = nil
            phase = .review
        } catch is CancellationError {
            return
        } catch {
            guard operationTaskSlot.isCurrent(taskID) else { return }
            failureMessage = error.localizedDescription
            phase = .failure
        }
    }

    @MainActor
    func solve(using model: AIAnswerModel, taskID: UUID) async {
        guard let recognition else { return }
        phase = .solving
        failedOperation = .solution
        selectedModel = model
        do {
            let value = try await AIService.solve(
                question: confirmedQuestion,
                recognition: recognition,
                using: model
            )
            try Task.checkCancellation()
            guard operationTaskSlot.isCurrent(taskID) else { return }
            solution = value
            phase = .result
        } catch is CancellationError {
            return
        } catch {
            guard operationTaskSlot.isCurrent(taskID) else { return }
            failureMessage = error.localizedDescription
            phase = .failure
        }
    }
}
