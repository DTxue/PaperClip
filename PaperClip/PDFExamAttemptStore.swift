import Foundation
import SwiftData

enum PDFExamAttemptStore {
    struct CacheResult {
        let url: URL
        let didUpdateAttempt: Bool
    }

    static func createAttempt(
        document: PDFDocumentItem,
        selectedPageIndices: [Int],
        in modelContext: ModelContext
    ) throws -> ExamAttempt {
        let fileName = try StorageService.createExamPDF(
            from: document.localFileURL,
            selectedPageIndices: selectedPageIndices
        )
        let attempt = ExamAttempt(
            sourceDocumentId: document.id,
            sourceDocumentTitle: document.title,
            sourceDocumentLocalFileName: document.localFileName,
            sourceDocumentFingerprint: stableFingerprint(for: document),
            generatedPDFFileName: fileName,
            selectedPageIndices: selectedPageIndices
        )
        modelContext.insert(attempt)
        do {
            try modelContext.saveOrRollbackIfNeeded()
            PDFExamArchiveStore.archiveBestEffort(attempt: attempt, in: modelContext)
        } catch {
            StorageService.deleteFileBestEffort(
                at: attempt.generatedPDFURL,
                context: "考试 PDF 保存失败后的文件清理失败"
            )
            throw error
        }
        return attempt
    }

    static func startOrResumeFullDocumentExam(
        document: PDFDocumentItem,
        in modelContext: ModelContext
    ) throws -> ExamAttempt {
        let pageCount = PDFPageDocumentReader.pageCount(in: document.localFileURL)
        guard pageCount > 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if let current = try modelContext.fetchResumableFullDocumentExamAttempt(
            document: document,
            sourcePageCount: pageCount
        ) {
            return current
        }
        return try createAttempt(
            document: document,
            selectedPageIndices: Array(0..<pageCount),
            in: modelContext
        )
    }

    static func ensurePDFCache(
        for attempt: ExamAttempt,
        sourceURL: URL,
        in modelContext: ModelContext
    ) throws -> CacheResult {
        if !attempt.generatedPDFFileName.isEmpty {
            let cached = attempt.generatedPDFURL
            if FileManager.default.fileExists(atPath: cached.path) {
                return CacheResult(url: cached, didUpdateAttempt: false)
            }
        }

        let fileName = try StorageService.createExamPDF(
            from: sourceURL,
            selectedPageIndices: attempt.selectedPageIndices
        )
        attempt.generatedPDFFileName = fileName
        attempt.updatedAt = .now
        do {
            try modelContext.saveOrRollbackIfNeeded()
            PDFExamArchiveStore.archiveBestEffort(attempt: attempt, in: modelContext)
        } catch {
            StorageService.deleteFileBestEffort(
                .examPDF(fileName: fileName),
                context: "考试 PDF 缓存保存失败后的文件清理失败"
            )
            throw error
        }
        return CacheResult(url: attempt.generatedPDFURL, didUpdateAttempt: true)
    }

    static func stableFingerprint(for document: PDFDocumentItem) -> String {
        if !document.fileFingerprint.isEmpty {
            return document.fileFingerprint
        }
        return (try? StorageService.sha256Fingerprint(for: document.localFileURL)) ?? ""
    }
}

struct PDFExamArchiveManifest: Codable {
    var version: Int
    var attemptID: UUID
    var sourceDocumentID: UUID
    var sourceDocumentTitle: String
    var sourceDocumentLocalFileName: String
    var sourceDocumentFingerprint: String
    var generatedPDFFileName: String
    var selectedPageIndices: [Int]
    var status: String
    var createdAt: Date
    var submittedAt: Date?
    var updatedAt: Date
    var archivedAt: Date
    var drawingFiles: [PDFExamArchiveDrawing]
    var gradeMarks: [PDFExamArchiveGradeMark]
    var pageSubmissions: [PDFExamArchivePageSubmission]?
}

struct PDFExamArchiveDrawing: Codable {
    var pageIndex: Int
    var fileName: String
}

struct PDFExamArchiveGradeMark: Codable {
    var id: UUID
    var pageIndex: Int
    var isCorrect: Bool
    var normalizedAnchor: String
    var confidence: Double
    var questionNumber: String
    var createdAt: Date
    var updatedAt: Date
}

struct PDFExamArchivePageSubmission: Codable {
    var id: UUID
    var pageIndex: Int
    var status: String
    var submittedAt: Date
    var gradedAt: Date?
    var updatedAt: Date
}

enum PDFExamArchiveStore {
    static func archiveBestEffort(
        attempt: ExamAttempt,
        in modelContext: ModelContext
    ) {
        do {
            try archiveCurrentState(attempt: attempt, in: modelContext)
        } catch {
            assertionFailure("考试记录归档失败：\(error.localizedDescription)")
        }
    }

    static func archiveCurrentState(
        attempt: ExamAttempt,
        in modelContext: ModelContext,
        archiveRoot: URL = AppStorageDirectory.examArchives
    ) throws {
        try archive(
            attempt: attempt,
            drawings: modelContext.fetchExamHandwritingLayers(attemptID: attempt.id),
            gradeMarks: modelContext.fetchExamGradeMarks(attemptID: attempt.id),
            pageSubmissions: modelContext.fetchExamPageSubmissions(attemptID: attempt.id),
            archiveRoot: archiveRoot
        )
    }

    @discardableResult
    static func restoreMissingArchives(in modelContext: ModelContext) throws -> Int {
        try restoreMissingArchives(
            in: modelContext,
            archiveRoot: AppStorageDirectory.examArchives
        )
    }

    @discardableResult
    static func restoreMissingArchives(
        in modelContext: ModelContext,
        archiveRoot: URL
    ) throws -> Int {
        try PDFArchiveDeletionFileStore.recoverInterruptedBatches(
            archiveRoot: archiveRoot,
            attemptExists: { attemptID in
                try modelContext.fetchExamAttempt(id: attemptID) != nil
            }
        )
        guard FileManager.default.fileExists(atPath: archiveRoot.path) else { return 0 }

        let archiveDirectories = try FileManager.default.contentsOfDirectory(
            at: archiveRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var restoredCount = 0
        for directory in archiveDirectories where (try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            let manifestURL = directory.appendingPathComponent("manifest.json")
            guard FileManager.default.fileExists(atPath: manifestURL.path) else { continue }
            let manifest = try JSONDecoder.examArchive.decode(
                PDFExamArchiveManifest.self,
                from: Data(contentsOf: manifestURL)
            )
            guard try modelContext.fetchExamAttempt(id: manifest.attemptID) == nil else { continue }
            guard let sourceDocument = try modelContext.fetchRecoverablePDFDocument(
                sourceDocumentID: manifest.sourceDocumentID,
                localFileName: manifest.sourceDocumentLocalFileName,
                fingerprint: manifest.sourceDocumentFingerprint
            ) else {
                // 没有源试卷的归档不可恢复。尤其是用户已删除试卷时，不能在下次启动
                // 重新创建孤立的考试记录。
                continue
            }

            let generatedPDFFileName = try restoreExamPDFIfNeeded(
                manifest: manifest,
                archiveDirectory: directory
            )
            let attempt = ExamAttempt(
                id: manifest.attemptID,
                sourceDocumentId: sourceDocument.id,
                sourceDocumentTitle: sourceDocument.title,
                sourceDocumentLocalFileName: sourceDocument.localFileName,
                sourceDocumentFingerprint: sourceDocument.fileFingerprint,
                generatedPDFFileName: generatedPDFFileName,
                selectedPageIndices: manifest.selectedPageIndices,
                status: manifest.status,
                createdAt: manifest.createdAt,
                submittedAt: manifest.submittedAt,
                updatedAt: manifest.updatedAt
            )
            modelContext.insert(attempt)

            for drawing in manifest.drawingFiles {
                let url = directory.appendingPathComponent(drawing.fileName)
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                modelContext.insert(ExamHandwritingLayer(
                    sourceDocumentId: sourceDocument.id,
                    attemptId: manifest.attemptID,
                    pageIndex: drawing.pageIndex,
                    drawingData: try Data(contentsOf: url),
                    createdAt: manifest.createdAt,
                    updatedAt: manifest.updatedAt
                ))
            }

            for mark in manifest.gradeMarks {
                modelContext.insert(ExamGradeMark(
                    id: mark.id,
                    sourceDocumentId: sourceDocument.id,
                    attemptId: manifest.attemptID,
                    pageIndex: mark.pageIndex,
                    isCorrect: mark.isCorrect,
                    normalizedAnchor: mark.normalizedAnchor,
                    confidence: mark.confidence,
                    questionNumber: mark.questionNumber,
                    createdAt: mark.createdAt,
                    updatedAt: mark.updatedAt
                ))
            }
            for submission in manifest.pageSubmissions ?? [] {
                modelContext.insert(ExamPageSubmission(
                    id: submission.id,
                    sourceDocumentId: sourceDocument.id,
                    attemptId: manifest.attemptID,
                    pageIndex: submission.pageIndex,
                    status: submission.status,
                    submittedAt: submission.submittedAt,
                    gradedAt: submission.gradedAt,
                    updatedAt: submission.updatedAt
                ))
            }
            restoredCount += 1
        }

        if restoredCount > 0 {
            try modelContext.saveOrRollbackIfNeeded()
        }
        return restoredCount
    }

    static func archive(
        attempt: ExamAttempt,
        drawings: [ExamHandwritingLayer],
        gradeMarks: [ExamGradeMark],
        pageSubmissions: [ExamPageSubmission],
        archiveRoot: URL = AppStorageDirectory.examArchives
    ) throws {
        let directory = archiveDirectory(for: attempt.id, archiveRoot: archiveRoot)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: attempt.generatedPDFURL.path) {
            let archivedPDF = directory.appendingPathComponent("exam.pdf")
            if FileManager.default.fileExists(atPath: archivedPDF.path) {
                try FileManager.default.removeItem(at: archivedPDF)
            }
            try FileManager.default.copyItem(at: attempt.generatedPDFURL, to: archivedPDF)
        }

        let drawingsDirectory = directory.appendingPathComponent("Drawings", isDirectory: true)
        try FileManager.default.createDirectory(at: drawingsDirectory, withIntermediateDirectories: true)
        let drawingFiles = try drawings.sorted { $0.pageIndex < $1.pageIndex }.map { layer in
            let fileName = "page-\(layer.pageIndex).drawing"
            let url = drawingsDirectory.appendingPathComponent(fileName)
            try layer.drawingData.write(to: url, options: .atomic)
            return PDFExamArchiveDrawing(pageIndex: layer.pageIndex, fileName: "Drawings/\(fileName)")
        }

        let manifest = PDFExamArchiveManifest(
            version: 2,
            attemptID: attempt.id,
            sourceDocumentID: attempt.sourceDocumentId,
            sourceDocumentTitle: attempt.sourceDocumentTitle,
            sourceDocumentLocalFileName: attempt.sourceDocumentLocalFileName,
            sourceDocumentFingerprint: attempt.sourceDocumentFingerprint,
            generatedPDFFileName: attempt.generatedPDFFileName,
            selectedPageIndices: attempt.selectedPageIndices,
            status: attempt.status,
            createdAt: attempt.createdAt,
            submittedAt: attempt.submittedAt,
            updatedAt: attempt.updatedAt,
            archivedAt: .now,
            drawingFiles: drawingFiles,
            gradeMarks: gradeMarks.sorted { $0.pageIndex < $1.pageIndex }.map {
                PDFExamArchiveGradeMark(
                    id: $0.id,
                    pageIndex: $0.pageIndex,
                    isCorrect: $0.isCorrect,
                    normalizedAnchor: $0.normalizedAnchor,
                    confidence: $0.confidence,
                    questionNumber: $0.questionNumber,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            pageSubmissions: pageSubmissions.sorted { $0.pageIndex < $1.pageIndex }.map {
                PDFExamArchivePageSubmission(
                    id: $0.id,
                    pageIndex: $0.pageIndex,
                    status: $0.status,
                    submittedAt: $0.submittedAt,
                    gradedAt: $0.gradedAt,
                    updatedAt: $0.updatedAt
                )
            }
        )
        let data = try JSONEncoder.examArchive.encode(manifest)
        try data.write(to: directory.appendingPathComponent("manifest.json"), options: .atomic)
    }

    private static func archiveDirectory(for attemptID: UUID, archiveRoot: URL) -> URL {
        archiveRoot.appendingPathComponent(attemptID.uuidString, isDirectory: true)
    }

    private static func restoreExamPDFIfNeeded(
        manifest: PDFExamArchiveManifest,
        archiveDirectory: URL
    ) throws -> String {
        let archivedPDF = archiveDirectory.appendingPathComponent("exam.pdf")
        guard FileManager.default.fileExists(atPath: archivedPDF.path) else {
            return manifest.generatedPDFFileName
        }

        let fileName = manifest.generatedPDFFileName.isEmpty
            ? "\(manifest.attemptID.uuidString).pdf"
            : manifest.generatedPDFFileName
        let destination = StoredFile.examPDF(fileName: fileName).url
        try StorageService.ensureParentDirectoryExists(for: destination)
        if !FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.copyItem(at: archivedPDF, to: destination)
            try? StorageService.makePDFReadOnly(at: destination)
        }
        return fileName
    }
}

extension PDFArtifactDeletionTransaction {
    static func deleteInProgressExamAttempt(
        id attemptID: UUID,
        in modelContext: ModelContext
    ) throws -> [URL] {
        try deleteInProgressExamAttempt(
            id: attemptID,
            in: modelContext,
            stageArchives: { attemptIDs in
                try PDFArchiveDeletionFileStore.stage(
                    attemptIDs: attemptIDs,
                    archiveRoot: AppStorageDirectory.examArchives
                )
            }
        )
    }

    static func deletePDFDocument(
        id documentID: UUID,
        localFileURL: URL,
        in modelContext: ModelContext
    ) throws -> [URL] {
        try deletePDFDocument(
            id: documentID,
            localFileURL: localFileURL,
            in: modelContext,
            stageArchives: { attemptIDs in
                try PDFArchiveDeletionFileStore.stage(
                    attemptIDs: attemptIDs,
                    archiveRoot: AppStorageDirectory.examArchives
                )
            }
        )
    }
}

private extension JSONEncoder {
    static var examArchive: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var examArchive: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
