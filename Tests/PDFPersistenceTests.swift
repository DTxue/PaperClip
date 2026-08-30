import Foundation
import SwiftData

@main
struct PDFPersistenceTests {
    @MainActor
    static func main() throws {
        try testArchiveDeletionBatchRollback()
        try testInterruptedArchiveDeletionRecovery()
        try testCurrentAttemptQueryIgnoresCompletedRounds()
        try testSubmittedRoundWithPendingPageGradingRemainsResumable()
        try testFullDocumentResumeDoesNotPickStaleLegacyPageTwentyThree()

        let schema = Schema([
            PDFDocumentItem.self,
            HandwritingLayer.self,
            ExamAttempt.self,
            ExamPageSubmission.self,
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

        let document = PDFDocumentItem(
            title: "期中试卷",
            localFileName: "paper.pdf",
            fileFingerprint: "paper-fingerprint"
        )
        let otherDocument = PDFDocumentItem(
            title: "期末试卷",
            localFileName: "other.pdf",
            fileFingerprint: "paper-fingerprint"
        )
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
        let submittedAttempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            generatedPDFFileName: "submitted.pdf",
            selectedPageIndices: [3],
            status: ExamAttemptStatus.submitted.rawValue
        )
        let staleSourceDocumentID = UUID()
        let relinkableAttempt = ExamAttempt(
            sourceDocumentId: staleSourceDocumentID,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            sourceDocumentFingerprint: document.fileFingerprint,
            generatedPDFFileName: "relinked.pdf",
            selectedPageIndices: [4]
        )
        let unrelatedDuplicateAttempt = ExamAttempt(
            sourceDocumentId: otherDocument.id,
            sourceDocumentTitle: otherDocument.title,
            sourceDocumentLocalFileName: otherDocument.localFileName,
            sourceDocumentFingerprint: otherDocument.fileFingerprint,
            generatedPDFFileName: "unrelated-duplicate.pdf",
            selectedPageIndices: [0]
        )
        context.insert(document)
        context.insert(otherDocument)
        context.insert(HandwritingLayer(documentId: document.id, pageIndex: 0, drawingData: Data([1])))
        context.insert(HandwritingLayer(documentId: otherDocument.id, pageIndex: 0, drawingData: Data([2])))
        context.insert(attempt)
        context.insert(otherAttempt)
        context.insert(submittedAttempt)
        context.insert(relinkableAttempt)
        context.insert(unrelatedDuplicateAttempt)
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
        let submittedAttemptLayer = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: submittedAttempt.id,
            pageIndex: 0,
            drawingData: Data([9])
        )
        context.insert(examLayer)
        context.insert(otherAttemptLayer)
        context.insert(submittedAttemptLayer)
        context.insert(ExamHandwritingLayer(
            sourceDocumentId: staleSourceDocumentID,
            attemptId: relinkableAttempt.id,
            pageIndex: 0,
            drawingData: Data([10])
        ))
        let unrelatedDuplicateLayer = ExamHandwritingLayer(
            sourceDocumentId: otherDocument.id,
            attemptId: unrelatedDuplicateAttempt.id,
            pageIndex: 0,
            drawingData: Data([11])
        )
        context.insert(unrelatedDuplicateLayer)
        context.insert(ExamGradeMark(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.5,0.5"
        ))
        context.insert(ExamPageSubmission(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 0
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: document.id,
            attemptId: otherAttempt.id,
            pageIndex: 0,
            isCorrect: false,
            normalizedAnchor: "0.4,0.4"
        ))
        context.insert(ExamGradeMark(
            sourceDocumentId: staleSourceDocumentID,
            attemptId: relinkableAttempt.id,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.3,0.3"
        ))
        try context.save()

        let documentAttemptsBeforeRepair = try context.fetchExamAttempts(document: document)
        expect(
            Set(documentAttemptsBeforeRepair.map(\.id))
                == [attempt.id, otherAttempt.id, submittedAttempt.id, relinkableAttempt.id]
        )
        try context.repairExamAttemptLinks(for: document)
        expect(relinkableAttempt.sourceDocumentId == document.id)
        expect(unrelatedDuplicateAttempt.sourceDocumentId == otherDocument.id)

        let recoverableDocument = try context.fetchRecoverablePDFDocument(
            sourceDocumentID: UUID(),
            localFileName: document.localFileName,
            fingerprint: document.fileFingerprint
        )
        expect(recoverableDocument?.id == document.id)

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

        do {
            _ = try context.deleteInProgressExamAttemptCascade(attemptID: submittedAttempt.id)
            fail("submitted exam attempts should not be deleted through in-progress deletion")
        } catch PDFExamAttemptDeletionError.notInProgress {
            let submittedAttemptLayers = try fetchExamLayers(attemptID: submittedAttempt.id, in: context)
            expect(submittedAttemptLayers.map(\.id) == [submittedAttemptLayer.id])
        } catch {
            fail("submitted deletion should fail with notInProgress")
        }

        do {
            _ = try context.planInProgressExamAttemptDeletion(attemptID: attempt.id)
            fail("attempts with submitted pages must not be deletable")
        } catch PDFExamAttemptDeletionError.hasSubmittedPages {
            let lockedSubmissions = try context.fetchExamPageSubmissions(attemptID: attempt.id)
            expect(lockedSubmissions.count == 1)
        } catch {
            fail("submitted-page deletion should fail with hasSubmittedPages")
        }

        let plannedAttemptArtifacts = try context.planInProgressExamAttemptDeletion(
            attemptID: otherAttempt.id
        )
        expect(plannedAttemptArtifacts.archiveAttemptIDs == [otherAttempt.id])
        let layersBeforeAttemptDeletion = try fetchExamLayers(attemptID: otherAttempt.id, in: context)
        expect(layersBeforeAttemptDeletion.count == 1)

        do {
            _ = try PDFArtifactDeletionTransaction.deleteInProgressExamAttempt(
                id: otherAttempt.id,
                in: context,
                stageArchives: { _ in throw ExpectedArchiveDeletionFailure() }
            )
            fail("archive failure must stop exam attempt deletion")
        } catch is ExpectedArchiveDeletionFailure {
            let attemptAfterArchiveFailure = try fetchExamAttempt(id: otherAttempt.id, in: context)
            expect(attemptAfterArchiveFailure != nil)
        }

        let transactionArchiveRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFDeletionTransactionTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: transactionArchiveRoot) }
        let otherAttemptArchive = transactionArchiveRoot
            .appendingPathComponent(otherAttempt.id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: otherAttemptArchive, withIntermediateDirectories: true)
        try Data("manifest".utf8).write(to: otherAttemptArchive.appendingPathComponent("manifest.json"))

        do {
            _ = try PDFArtifactDeletionTransaction.deleteInProgressExamAttempt(
                id: otherAttempt.id,
                in: context,
                stageArchives: { attemptIDs in
                    let batch = try PDFArchiveDeletionFileStore.stage(
                        attemptIDs: attemptIDs,
                        archiveRoot: transactionArchiveRoot
                    )
                    otherAttempt.status = ExamAttemptStatus.submitted.rawValue
                    return batch
                }
            )
            fail("database failure must roll staged archives back")
        } catch PDFExamAttemptDeletionError.notInProgress {
            otherAttempt.status = ExamAttemptStatus.inProgress.rawValue
            expect(FileManager.default.fileExists(atPath: otherAttemptArchive.path))
        }

        let deletedAttemptFileURLs = try PDFArtifactDeletionTransaction.deleteInProgressExamAttempt(
            id: otherAttempt.id,
            in: context,
            stageArchives: { attemptIDs in
                try PDFArchiveDeletionFileStore.stage(
                    attemptIDs: attemptIDs,
                    archiveRoot: transactionArchiveRoot
                )
            }
        )
        let deletedAttemptFileNames = Set(deletedAttemptFileURLs.map(\.lastPathComponent))
        let deletedAttempt = try fetchExamAttempt(id: otherAttempt.id, in: context)
        let deletedAttemptLayers = try fetchExamLayers(attemptID: otherAttempt.id, in: context)
        let deletedAttemptGradeMarks = try fetchGradeMarks(attemptID: otherAttempt.id, in: context)
        let keptAttempt = try fetchExamAttempt(id: attempt.id, in: context)
        expect(deletedAttemptFileNames == ["exam-2.pdf"])
        expect(!FileManager.default.fileExists(atPath: otherAttemptArchive.path))
        expect(deletedAttempt == nil)
        expect(deletedAttemptLayers.isEmpty)
        expect(deletedAttemptGradeMarks.isEmpty)
        expect(keptAttempt != nil)

        let plannedDeletionArtifacts = try context.planPDFDocumentDeletion(
            documentID: document.id,
            localFileURL: document.localFileURL
        )
        expect(
            Set(plannedDeletionArtifacts.archiveAttemptIDs)
                == [attempt.id, submittedAttempt.id, relinkableAttempt.id]
        )
        let attemptBeforeDeletion = try fetchExamAttempt(id: attempt.id, in: context)
        expect(attemptBeforeDeletion != nil)

        do {
            _ = try PDFArtifactDeletionTransaction.deletePDFDocument(
                id: document.id,
                localFileURL: document.localFileURL,
                in: context,
                stageArchives: { _ in throw ExpectedArchiveDeletionFailure() }
            )
            fail("archive failure must stop PDF document deletion")
        } catch is ExpectedArchiveDeletionFailure {
            let documentAfterArchiveFailure = try context.fetchPDFDocument(id: document.id)
            expect(documentAfterArchiveFailure != nil)
            let attemptAfterArchiveFailure = try fetchExamAttempt(id: attempt.id, in: context)
            expect(attemptAfterArchiveFailure != nil)
        }

        for attemptID in plannedDeletionArtifacts.archiveAttemptIDs {
            let archive = transactionArchiveRoot
                .appendingPathComponent(attemptID.uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
            try Data("manifest".utf8).write(to: archive.appendingPathComponent("manifest.json"))
        }
        let deletedDocumentFileURLs = try PDFArtifactDeletionTransaction.deletePDFDocument(
            id: document.id,
            localFileURL: document.localFileURL,
            in: context,
            stageArchives: { attemptIDs in
                try PDFArchiveDeletionFileStore.stage(
                    attemptIDs: attemptIDs,
                    archiveRoot: transactionArchiveRoot
                )
            }
        )

        let fileNames = Set(deletedDocumentFileURLs.map(\.lastPathComponent))
        let remainingDocuments = try context.fetch(FetchDescriptor<PDFDocumentItem>())
        let remainingHandwritingLayers = try context.fetch(FetchDescriptor<HandwritingLayer>())
        let remainingAttempts = try context.fetch(FetchDescriptor<ExamAttempt>())
        let remainingExamLayers = try context.fetch(FetchDescriptor<ExamHandwritingLayer>())
        let remainingGradeMarks = try context.fetch(FetchDescriptor<ExamGradeMark>())

        expect(fileNames == ["paper.pdf", "exam.pdf", "submitted.pdf", "relinked.pdf"])
        for attemptID in plannedDeletionArtifacts.archiveAttemptIDs {
            let archive = transactionArchiveRoot
                .appendingPathComponent(attemptID.uuidString, isDirectory: true)
            expect(!FileManager.default.fileExists(atPath: archive.path))
        }
        expect(remainingDocuments.map(\.id) == [otherDocument.id])
        expect(remainingHandwritingLayers.map(\.documentId) == [otherDocument.id])
        expect(remainingAttempts.map(\.id) == [unrelatedDuplicateAttempt.id])
        expect(remainingExamLayers.map(\.id) == [unrelatedDuplicateLayer.id])
        expect(remainingGradeMarks.isEmpty)
        let deletedDocumentMustNotRecover = try context.fetchRecoverablePDFDocument(
            sourceDocumentID: document.id,
            localFileName: document.localFileName,
            fingerprint: document.fileFingerprint
        )
        expect(deletedDocumentMustNotRecover == nil)

        print("PDFPersistenceTests: 34 passed")
    }

    @MainActor
    private static func testFullDocumentResumeDoesNotPickStaleLegacyPageTwentyThree() throws {
        let schema = Schema([
            PDFDocumentItem.self,
            ExamAttempt.self,
            ExamPageSubmission.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let document = PDFDocumentItem(title: "25 页试卷", localFileName: "legacy-resume.pdf")
        let stalePageTwentyThree = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            generatedPDFFileName: "legacy-page-23.pdf",
            selectedPageIndices: [22],
            status: ExamAttemptStatus.inProgress.rawValue,
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let latestCompletedPageOne = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            generatedPDFFileName: "latest-page-1.pdf",
            selectedPageIndices: [0],
            status: ExamAttemptStatus.graded.rawValue,
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        context.insert(document)
        context.insert(stalePageTwentyThree)
        context.insert(latestCompletedPageOne)
        try context.save()

        let resumable = try context.fetchResumableFullDocumentExamAttempt(
            document: document,
            sourcePageCount: 25
        )
        expect(resumable == nil)
    }

    @MainActor
    private static func testSubmittedRoundWithPendingPageGradingRemainsResumable() throws {
        let schema = Schema([
            PDFDocumentItem.self,
            ExamAttempt.self,
            ExamPageSubmission.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let document = PDFDocumentItem(title: "待批阅续考", localFileName: "pending-resume.pdf")
        let attempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            generatedPDFFileName: "pending-resume-exam.pdf",
            selectedPageIndices: [0, 1],
            status: ExamAttemptStatus.submitted.rawValue
        )
        context.insert(document)
        context.insert(attempt)
        context.insert(ExamPageSubmission(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 0,
            status: ExamPageSubmissionStatus.graded.rawValue
        ))
        let pendingSubmission = ExamPageSubmission(
            sourceDocumentId: document.id,
            attemptId: attempt.id,
            pageIndex: 1,
            status: ExamPageSubmissionStatus.submitted.rawValue
        )
        context.insert(pendingSubmission)
        try context.save()

        let resumable = try context.fetchResumableFullDocumentExamAttempt(
            document: document,
            sourcePageCount: 2
        )
        expect(resumable?.id == attempt.id)

        pendingSubmission.status = ExamPageSubmissionStatus.graded.rawValue
        try context.save()
        let afterGrading = try context.fetchResumableFullDocumentExamAttempt(
            document: document,
            sourcePageCount: 2
        )
        expect(afterGrading == nil)
    }

    @MainActor
    private static func testCurrentAttemptQueryIgnoresCompletedRounds() throws {
        let schema = Schema([PDFDocumentItem.self, ExamAttempt.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let document = PDFDocumentItem(title: "继续考试", localFileName: "resume.pdf")
        let completed = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            generatedPDFFileName: "completed.pdf",
            selectedPageIndices: [0, 1],
            status: ExamAttemptStatus.graded.rawValue,
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        let current = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            generatedPDFFileName: "current.pdf",
            selectedPageIndices: [0, 1],
            status: ExamAttemptStatus.inProgress.rawValue,
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        context.insert(document)
        context.insert(completed)
        context.insert(current)
        try context.save()

        let fetchedCurrent = try context.fetchCurrentExamAttempt(document: document)
        expect(fetchedCurrent?.id == current.id)
        current.status = ExamAttemptStatus.submitted.rawValue
        try context.save()
        let currentAfterSubmission = try context.fetchCurrentExamAttempt(document: document)
        expect(currentAfterSubmission == nil)
    }

    private static func testArchiveDeletionBatchRollback() throws {
        let archiveRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFArchiveDeletionBatchTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: archiveRoot) }

        let attemptID = UUID()
        let archiveDirectory = archiveRoot.appendingPathComponent(attemptID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        try Data("manifest".utf8).write(to: archiveDirectory.appendingPathComponent("manifest.json"))

        let batch = try PDFArchiveDeletionFileStore.stage(
            attemptIDs: [attemptID],
            archiveRoot: archiveRoot
        )
        expect(!FileManager.default.fileExists(atPath: archiveDirectory.path))
        try batch.rollback()
        expect(FileManager.default.fileExists(atPath: archiveDirectory.path))
    }

    private static func testInterruptedArchiveDeletionRecovery() throws {
        let archiveRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFArchiveDeletionRecoveryTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: archiveRoot) }

        let attemptID = UUID()
        let archiveDirectory = archiveRoot.appendingPathComponent(attemptID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        _ = try PDFArchiveDeletionFileStore.stage(
            attemptIDs: [attemptID],
            archiveRoot: archiveRoot
        )

        let recoveredCount = try PDFArchiveDeletionFileStore.recoverInterruptedBatches(
            archiveRoot: archiveRoot,
            attemptExists: { $0 == attemptID }
        )
        expect(recoveredCount == 1)
        expect(FileManager.default.fileExists(atPath: archiveDirectory.path))

        _ = try PDFArchiveDeletionFileStore.stage(
            attemptIDs: [attemptID],
            archiveRoot: archiveRoot
        )
        let discardedCount = try PDFArchiveDeletionFileStore.recoverInterruptedBatches(
            archiveRoot: archiveRoot,
            attemptExists: { _ in false }
        )
        expect(discardedCount == 0)
        expect(!FileManager.default.fileExists(atPath: archiveDirectory.path))
        let remainingStagingRoots = try FileManager.default.contentsOfDirectory(
            at: archiveRoot,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix(PDFArchiveDeletionFileStore.stagingPrefix) }
        expect(remainingStagingRoots.isEmpty)
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

    private static func fetchExamAttempt(
        id: UUID,
        in context: ModelContext
    ) throws -> ExamAttempt? {
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func fetchGradeMarks(
        attemptID: UUID,
        in context: ModelContext
    ) throws -> [ExamGradeMark] {
        try context.fetch(FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
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

    private static func fail(
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        fatalError(message, file: file, line: line)
    }
}

private struct ExpectedArchiveDeletionFailure: Error {}

enum StorageService {
    static func sha256Fingerprint(for url: URL) throws -> String { "" }
}
