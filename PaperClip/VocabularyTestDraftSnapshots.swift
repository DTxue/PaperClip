import Foundation
import PencilKit

struct VocabularyTestDraftRestoreResult {
    let batches: [VocabularyTestBatch]
    let drawingDataCache: VocabularyDraftDrawingDataCache
    let currentBatchIndex: Int
    let currentQuestionIndex: Int
    let currentDrawing: PKDrawing
    let currentDrawingData: Data
    let questionCount: Int
}

@MainActor
enum VocabularyTestDraftRestorer {
    static func restore(
        draft: VocabularyTestDraft,
        cards: [VocabularyCard]
    ) -> VocabularyTestDraftRestoreResult? {
        let maximumQuestionCount = VocabularyTestQuestionCount.clamped(cards.count)
        var cardByID: [UUID: VocabularyCard] = [:]
        cardByID.reserveCapacity(cards.count)
        for card in cards where cardByID[card.id] == nil {
            cardByID[card.id] = card
        }
        let drawingDataCache = VocabularyDraftDrawingDataCache()
        var batches: [VocabularyTestBatch] = []

        for snapshot in draft.batches {
            let batchCards = snapshot.cardIDs.compactMap { cardByID[$0] }
            guard !batchCards.isEmpty else { continue }

            for index in snapshot.drawingsData.indices {
                drawingDataCache.set(
                    snapshot.drawingsData[index],
                    for: VocabularyDraftDrawingKey(batchID: snapshot.id, drawingIndex: index)
                )
            }

            let drawings = snapshot.drawingsData.map(DrawingDataSupport.drawingOrEmpty)
            let restoredStatus = restoredBatchStatus(
                snapshotStatus: snapshot.status,
                didFinishAnswering: draft.didFinishAnswering
            )
            batches.append(VocabularyTestBatch(
                id: snapshot.id,
                startIndex: snapshot.startIndex,
                cards: batchCards,
                drawings: drawings,
                renderedImages: restoredStatus.status == .graded
                    ? VocabularyHandwritingImageRenderer.renderOnMainActor(drawings)
                    : [],
                status: restoredStatus.status,
                gradingAttempts: snapshot.gradingAttempts,
                result: snapshot.result,
                errorMessage: restoredStatus.errorMessage ?? snapshot.errorMessage
            ))
        }

        guard !batches.isEmpty else { return nil }

        let batchIndex = min(draft.currentBatchIndex, max(0, batches.count - 1))
        let questionIndex = min(
            draft.currentQuestionIndex,
            max(0, batches[batchIndex].cards.count - 1)
        )
        let currentDrawing = DrawingDataSupport.drawingOrEmpty(from: draft.currentDrawingData)

        return VocabularyTestDraftRestoreResult(
            batches: batches,
            drawingDataCache: drawingDataCache,
            currentBatchIndex: batchIndex,
            currentQuestionIndex: questionIndex,
            currentDrawing: currentDrawing,
            currentDrawingData: draft.currentDrawingData,
            questionCount: VocabularyTestQuestionCount.clamped(min(draft.batchSize, maximumQuestionCount))
        )
    }

    private static func restoredBatchStatus(
        snapshotStatus: String,
        didFinishAnswering: Bool
    ) -> (status: VocabularyTestBatchStatus, errorMessage: String?) {
        let status = VocabularyTestBatchStatus(rawValue: snapshotStatus) ?? .answering
        if status == .grading || status == .retrying {
            return (.failed, "上次批阅中断，请重新提交。")
        }
        if didFinishAnswering && status == .answering {
            return (.failed, "该组尚未完成批阅，请重新提交。")
        }
        return (status, nil)
    }
}
