import Foundation
import PencilKit

struct VocabularyHandwritingGradingCard: Sendable {
    let term: String
    let definition: String
    let englishDefinition: String
}

struct VocabularyBatchGradingRequest {
    let batchIndex: Int
    let batchID: Int
    let context: VocabularyTestGradingTaskContext
    let kind: VocabularyHandwritingTestKind
    let cards: [VocabularyHandwritingGradingCard]
    let drawings: [PKDrawing]
    let automaticRetry: Bool
}

struct VocabularyBatchGradingCallbacks {
    let isCurrent: @MainActor @Sendable (VocabularyTestGradingTaskContext, Int, Int) -> Bool
    let markAttempt: @MainActor @Sendable (Int, Int, VocabularyTestBatchStatus) -> Void
    let finishSuccess: @MainActor @Sendable (Int, [UIImage?], VocabularyGradingResult, VocabularyTestGradingTaskContext) -> Void
    let finishFailure: @MainActor @Sendable (Int, [UIImage?], String, VocabularyTestGradingTaskContext) -> Void
    let clearTask: @MainActor @Sendable (Int, UUID) -> Void
}

enum VocabularyBatchGradingRunner {
    static func makeTask(
        request: VocabularyBatchGradingRequest,
        callbacks: VocabularyBatchGradingCallbacks
    ) -> Task<Void, Never> {
        Task {
            @MainActor
            func isCurrentBatch() -> Bool {
                callbacks.isCurrent(request.context, request.batchID, request.batchIndex)
            }

            let images = await VocabularyHandwritingImageRenderer.render(request.drawings)
            guard !Task.isCancelled else {
                await callbacks.clearTask(request.batchID, request.context.taskID)
                return
            }
            let hasVisibleAnswers = images.map { $0 != nil }

            let maxAttempts = request.automaticRetry ? 2 : 1
            var lastErrorMessage = ""

            for attempt in 1...maxAttempts {
                let status: VocabularyTestBatchStatus = attempt == 1 ? .grading : .retrying
                let canContinue = await MainActor.run {
                    guard isCurrentBatch() else {
                        return false
                    }
                    callbacks.markAttempt(request.batchIndex, attempt, status)
                    return true
                }
                guard canContinue, !Task.isCancelled else { break }

                do {
                    let result: VocabularyGradingResult
                    if hasVisibleAnswers.contains(true) {
                        let aiResult: VocabularyGradingResult
                        switch request.kind {
                        case .spelling:
                            aiResult = try await AIService.gradeVocabularyTest(
                                cards: request.cards.map { ($0.term, $0.definition) },
                                handwritingImages: images
                            )
                        case .englishDefinition:
                            aiResult = try await AIService.recognizeVocabularyHandwriting(
                                prompts: request.cards.map(\.term),
                                handwritingImages: images
                            )
                        }
                        result = VocabularyGradingPolicy.validated(
                            aiResult,
                            expectedAnswers: request.cards.map {
                                request.kind.referenceAnswer(
                                    term: $0.term,
                                    englishDefinition: $0.englishDefinition
                                )
                            },
                            hasVisibleAnswers: hasVisibleAnswers,
                            matchPolicy: request.kind == .englishDefinition
                                ? .englishDefinition
                                : .spelling
                        )
                    } else {
                        result = VocabularyGradingPolicy.validated(
                            VocabularyGradingResult(items: []),
                            expectedAnswers: request.cards.map {
                                request.kind.referenceAnswer(
                                    term: $0.term,
                                    englishDefinition: $0.englishDefinition
                                )
                            },
                            hasVisibleAnswers: hasVisibleAnswers,
                            matchPolicy: request.kind == .englishDefinition
                                ? .englishDefinition
                                : .spelling
                        )
                    }
                    await MainActor.run {
                        guard isCurrentBatch() else {
                            return
                        }
                        callbacks.finishSuccess(
                            request.batchIndex,
                            images,
                            result,
                            request.context
                        )
                    }
                    return
                } catch is CancellationError {
                    break
                } catch {
                    lastErrorMessage = error.localizedDescription
                    if attempt < maxAttempts, !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                    }
                }
            }

            await MainActor.run {
                guard isCurrentBatch() else {
                    return
                }
                guard !Task.isCancelled else {
                    callbacks.clearTask(request.batchID, request.context.taskID)
                    return
                }
                callbacks.finishFailure(
                    request.batchIndex,
                    images,
                    lastErrorMessage,
                    request.context
                )
            }
        }
    }
}
