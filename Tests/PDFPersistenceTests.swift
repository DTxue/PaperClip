import Foundation
import SwiftData

@main
struct PDFPersistenceTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            PDFDocumentItem.self,
            HandwritingLayer.self,
            ExamAttempt.self,
            ExamHandwritingLayer.self,
            ExamGradeMark.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(PDFDocumentItem.deletionPropertiesToFetch.count == 1)
        expect(HandwritingLayer.deletionPropertiesToFetch.count == 1)
        expect(ExamAttempt.cascadeDeletionPropertiesToFetch.count == 2)
        expect(ExamHandwritingLayer.deletionPropertiesToFetch.count == 1)
        expect(ExamGradeMark.deletionPropertiesToFetch.count == 1)

        let document = PDFDocumentItem(title: "期中试卷", localFileName: "paper.pdf")
        let otherDocument = PDFDocumentItem(title: "期末试卷", localFileName: "other.pdf")
        let attempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            generatedPDFFileName: "exam.pdf",
            selectedPageIndices: [0, 1]
        )
        let otherAttempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            generatedPDFFileName: "exam-2.pdf",
            selectedPageIndices: [2]
        )
        context.insert(document)
        context.insert(otherDocument)
        context.insert(HandwritingLayer(documentId: document.id, pageIndex: 0, drawingData: Data([1])))
        context.insert(HandwritingLayer(documentId: otherDocument.id, pageIndex: 0, drawingData: Data([2])))
        context.insert(attempt)
        context.insert(otherAttempt)
        let examLayer = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 0,
            drawingData: Data([3])
        )
        let otherAttemptLayer = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: otherAttempt.id,
            pageIndex: 0,
            drawingData: Data([8])
        )
        context.insert(examLayer)
        context.insert(otherAttemptLayer)
        context.insert(ExamGradeMark(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.5,0.5"
        ))
        try context.save()

        let answerLayerStore = PDFAnswerLayerStore(modelContext: context)
        let flushResult = try answerLayerStore.savePendingDrawingData(
            sourceDocumentID: document.id,
            attempt: attempt,
            pendingDrawingDataByPage: [
                0: Data([3]),
                1: Data([4])
            ],
            currentDrawingDataByPage: [
                0: Data([3])
            ],
            currentLayersByPage: [
                0: examLayer
            ]
        )
        let attemptID = attempt.id
        let examLayersAfterFlush = try fetchExamLayers(attemptID: attemptID, in: context)
        expect(flushResult.didSave)
        expect(flushResult.completedPageIndices == Set([0, 1]))
        expect(flushResult.drawingDataByPage[0] == Data([3]))
        expect(flushResult.drawingDataByPage[1] == Data([4]))
        expect(flushResult.layersByPage[0]?.id == examLayer.id)
        expect(flushResult.layersByPage[1]?.drawingData == Data([4]))
        expect(examLayersAfterFlush.count == 2)

        let unchangedFlushResult = try answerLayerStore.savePendingDrawingData(
            sourceDocumentID: document.id,
            attempt: attempt,
            pendingDrawingDataByPage: [
                0: Data([3]),
                1: Data([4])
            ],
            currentDrawingDataByPage: flushResult.drawingDataByPage,
            currentLayersByPage: flushResult.layersByPage
        )
        expect(!unchangedFlushResult.didSave)
        expect(unchangedFlushResult.completedPageIndices == Set([0, 1]))

        let base = Date(timeIntervalSince1970: 1_000)
        let oldDuplicate = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 2,
            drawingData: Data([5]),
            createdAt: base,
            updatedAt: base
        )
        let latestDuplicate = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 2,
            drawingData: Data([6]),
            createdAt: base,
            updatedAt: base.addingTimeInterval(10)
        )
        context.insert(oldDuplicate)
        context.insert(latestDuplicate)
        try context.save()

        let latestLayers = try answerLayerStore.loadLatestLayers(attemptID: attempt.id)
        expect(latestLayers.latest[2]?.id == latestDuplicate.id)
        expect(latestLayers.duplicates.map(\.id) == [oldDuplicate.id])
        let didDeleteDuplicates = try answerLayerStore.deleteDuplicateLayers(latestLayers.duplicates)
        expect(didDeleteDuplicates)
        let layersAfterDuplicateCleanup = try fetchExamLayers(attemptID: attempt.id, in: context)
        expect(layersAfterDuplicateCleanup.map(\.pageIndex).sorted() == [0, 1, 2])

        let didClearAnswers = try answerLayerStore.clearAnswers(for: attempt)
        expect(didClearAnswers)
        let layersAfterClear = try fetchExamLayers(attemptID: attempt.id, in: context)
        let otherAttemptLayersAfterClear = try fetchExamLayers(attemptID: otherAttempt.id, in: context)
        expect(layersAfterClear.isEmpty)
        expect(otherAttemptLayersAfterClear.map(\.id) == [otherAttemptLayer.id])

        let fileURLs = try context.deletePDFDocumentCascade(
            documentID: document.id,
            localFileURL: document.localFileURL
        )
        try context.save()

        let fileNames = Set(fileURLs.map(\.lastPathComponent))
        let remainingDocuments = try context.fetch(FetchDescriptor<PDFDocumentItem>())
        let remainingHandwritingLayers = try context.fetch(FetchDescriptor<HandwritingLayer>())
        let remainingAttempts = try context.fetch(FetchDescriptor<ExamAttempt>())
        let remainingExamLayers = try context.fetch(FetchDescriptor<ExamHandwritingLayer>())
        let remainingGradeMarks = try context.fetch(FetchDescriptor<ExamGradeMark>())

        expect(fileNames == ["paper.pdf", "exam.pdf", "exam-2.pdf"])
        expect(remainingDocuments.map(\.id) == [otherDocument.id])
        expect(remainingHandwritingLayers.map(\.documentId) == [otherDocument.id])
        expect(remainingAttempts.isEmpty)
        expect(remainingExamLayers.isEmpty)
        expect(remainingGradeMarks.isEmpty)

        print("PDFPersistenceTests: 30 passed")
    }

    private static func fetchExamLayers(
        attemptID: UUID,
        in context: ModelContext
    ) throws -> [ExamHandwritingLayer] {
        try context.fetch(FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            },
            sortBy: [SortDescriptor(\.pageIndex)]
        ))
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
