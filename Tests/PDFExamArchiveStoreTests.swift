import Foundation
import SwiftData

@main
struct PDFExamArchiveStoreTests {
    @MainActor
    static func main() throws {
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

        let archiveRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFExamArchiveStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: archiveRoot) }

        let document = PDFDocumentItem(
            title: "归档恢复试卷",
            localFileName: "archive-source.pdf",
            fileFingerprint: "archive-source-fingerprint"
        )
        context.insert(document)
        try context.save()

        let currentStateAttempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            generatedPDFFileName: "",
            selectedPageIndices: [0, 1]
        )
        let currentStateDrawing = ExamHandwritingLayer(
            sourceDocumentId: document.id,
            attemptId: currentStateAttempt.id,
            pageIndex: 0,
            drawingData: Data([1, 2, 3])
        )
        let currentStateMark = ExamGradeMark(
            sourceDocumentId: document.id,
            attemptId: currentStateAttempt.id,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.5,0.5"
        )
        let currentStateSubmission = ExamPageSubmission(
            sourceDocumentId: document.id,
            attemptId: currentStateAttempt.id,
            pageIndex: 0,
            status: ExamPageSubmissionStatus.graded.rawValue
        )
        context.insert(currentStateAttempt)
        context.insert(currentStateDrawing)
        context.insert(currentStateMark)
        context.insert(currentStateSubmission)
        try context.save()

        try PDFExamArchiveStore.archiveCurrentState(
            attempt: currentStateAttempt,
            in: context,
            archiveRoot: archiveRoot
        )
        let currentManifest = try readManifest(
            attemptID: currentStateAttempt.id,
            archiveRoot: archiveRoot
        )
        expect(currentManifest.drawingFiles.count == 1)
        expect(currentManifest.gradeMarks.count == 1)
        expect(currentManifest.pageSubmissions?.count == 1)
        expect(currentManifest.pageSubmissions?.first?.status == ExamPageSubmissionStatus.graded.rawValue)

        let attemptID = UUID()
        try writeArchiveManifest(
            attemptID: attemptID,
            document: document,
            archiveRoot: archiveRoot
        )

        let restoredCount = try PDFExamArchiveStore.restoreMissingArchives(
            in: context,
            archiveRoot: archiveRoot
        )
        expect(restoredCount == 1)
        try expect(try context.fetchExamAttempt(id: attemptID) != nil)
        let restoredSubmissions = try context.fetchExamPageSubmissions(attemptID: attemptID)
        expect(restoredSubmissions.count == 1)
        expect(restoredSubmissions.first?.status == ExamPageSubmissionStatus.graded.rawValue)

        _ = try context.deletePDFDocumentCascade(
            documentID: document.id,
            localFileURL: document.localFileURL
        )
        try context.save()
        try expect(try context.fetchExamAttempt(id: attemptID) == nil)
        try expect(try context.fetchExamPageSubmissions(attemptID: attemptID).isEmpty)

        let restoredAfterDeletion = try PDFExamArchiveStore.restoreMissingArchives(
            in: context,
            archiveRoot: archiveRoot
        )
        expect(restoredAfterDeletion == 0)
        try expect(try context.fetchExamAttempt(id: attemptID) == nil)

        print("PDFExamArchiveStoreTests: 13 passed")
    }

    private static func readManifest(
        attemptID: UUID,
        archiveRoot: URL
    ) throws -> PDFExamArchiveManifest {
        let data = try Data(contentsOf: archiveRoot
            .appendingPathComponent(attemptID.uuidString, isDirectory: true)
            .appendingPathComponent("manifest.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PDFExamArchiveManifest.self, from: data)
    }

    private static func writeArchiveManifest(
        attemptID: UUID,
        document: PDFDocumentItem,
        archiveRoot: URL
    ) throws {
        let archiveDirectory = archiveRoot
            .appendingPathComponent(attemptID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let manifest = PDFExamArchiveManifest(
            version: 1,
            attemptID: attemptID,
            sourceDocumentID: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            sourceDocumentFingerprint: document.fileFingerprint,
            generatedPDFFileName: "archive-exam.pdf",
            selectedPageIndices: [0],
            status: ExamAttemptStatus.inProgress.rawValue,
            createdAt: now,
            submittedAt: nil,
            updatedAt: now,
            archivedAt: now,
            drawingFiles: [],
            gradeMarks: [],
            pageSubmissions: [
                PDFExamArchivePageSubmission(
                    id: UUID(),
                    pageIndex: 0,
                    status: ExamPageSubmissionStatus.graded.rawValue,
                    submittedAt: now,
                    gradedAt: now,
                    updatedAt: now
                )
            ]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(
            to: archiveDirectory.appendingPathComponent("manifest.json"),
            options: .atomic
        )
    }

    private static func expect(
        _ condition: @autoclosure () throws -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) rethrows {
        guard try condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}

// PDFExamAttemptStore 的恢复路径不需要 PDFKit。纯 Swift 集成测试提供未执行的
// StorageService 适配器，使归档恢复可在 macOS 测试进程中独立编译。
enum StorageService {
    static func createExamPDF(from sourceURL: URL, selectedPageIndices: [Int]) throws -> String {
        throw CocoaError(.featureUnsupported)
    }

    static func deleteFileBestEffort(at url: URL, context: String) {}

    static func deleteFileBestEffort(_ storedFile: StoredFile, context: String) {}

    static func sha256Fingerprint(for url: URL) throws -> String { "" }

    static func ensureParentDirectoryExists(for url: URL) throws {}

    static func makePDFReadOnly(at url: URL) throws {}
}

enum PDFPageDocumentReader {
    static func pageCount(in documentURL: URL) -> Int { 0 }
}
