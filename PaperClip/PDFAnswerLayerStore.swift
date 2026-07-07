import Foundation
import SwiftData

@MainActor
struct PDFAnswerLayerStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadLatestLayers(attemptID: UUID) throws -> LatestLayersByPage<ExamHandwritingLayer> {
        var descriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = ExamHandwritingLayer.workspacePropertiesToFetch
        let layers = try modelContext.fetch(descriptor)
        return latestLayersByPage(
            layers,
            pageIndex: \.pageIndex,
            updatedAt: \.updatedAt
        )
    }

    @discardableResult
    func deleteDuplicateLayers(_ duplicates: [ExamHandwritingLayer]) throws -> Bool {
        guard !duplicates.isEmpty else { return false }
        duplicates.forEach(modelContext.delete)
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }

    func savePendingDrawingData(
        sourceDocumentID: UUID,
        attempt: ExamAttempt,
        pendingDrawingDataByPage: [Int: Data],
        currentDrawingDataByPage: [Int: Data],
        currentLayersByPage: [Int: ExamHandwritingLayer]
    ) throws -> PDFAnswerLayerStoreFlushResult {
        let plan = PDFAnswerLayerWritePlan.make(
            currentDrawingDataByPage: currentDrawingDataByPage,
            pendingDrawingDataByPage: pendingDrawingDataByPage
        )
        guard plan.hasChanges else {
            return PDFAnswerLayerStoreFlushResult(
                didSave: false,
                drawingDataByPage: currentDrawingDataByPage,
                layersByPage: currentLayersByPage,
                completedPageIndices: plan.completedPageIndices
            )
        }

        var nextDrawingDataByPage = currentDrawingDataByPage
        var nextLayersByPage = currentLayersByPage
        let now = Date.now

        for (pageIndex, drawingData) in plan.changedDrawingDataByPage {
            nextDrawingDataByPage[pageIndex] = drawingData
            if let layer = nextLayersByPage[pageIndex] {
                layer.drawingData = drawingData
                layer.updatedAt = now
            } else {
                let layer = ExamHandwritingLayer(
                    sourceDocumentId: sourceDocumentID,
                    attemptId: attempt.id,
                    pageIndex: pageIndex,
                    drawingData: drawingData,
                    createdAt: now,
                    updatedAt: now
                )
                modelContext.insert(layer)
                nextLayersByPage[pageIndex] = layer
            }
        }

        attempt.updatedAt = now
        try modelContext.saveOrRollbackIfNeeded()
        return PDFAnswerLayerStoreFlushResult(
            didSave: true,
            drawingDataByPage: nextDrawingDataByPage,
            layersByPage: nextLayersByPage,
            completedPageIndices: plan.completedPageIndices
        )
    }

    @discardableResult
    func clearAnswers(for attempt: ExamAttempt) throws -> Bool {
        let attemptID = attempt.id
        var descriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = ExamHandwritingLayer.deletionPropertiesToFetch
        try modelContext.deleteFetched(descriptor)
        attempt.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }
}

struct PDFAnswerLayerStoreFlushResult {
    let didSave: Bool
    let drawingDataByPage: [Int: Data]
    let layersByPage: [Int: ExamHandwritingLayer]
    let completedPageIndices: Set<Int>
}
