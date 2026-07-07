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
            PDFExamArchiveStore.archiveBestEffort(attempt: attempt)
        } catch {
            StorageService.deleteFileBestEffort(
                at: attempt.generatedPDFURL,
                context: "考试 PDF 保存失败后的文件清理失败"
            )
            throw error
        }
        return attempt
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
            PDFExamArchiveStore.archiveBestEffort(attempt: attempt)
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

enum PDFExamArchiveStore {
    @discardableResult
    static func restoreMissingArchives(in modelContext: ModelContext) throws -> Int {
        let archiveRoot = AppStorageDirectory.examArchives
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

            let generatedPDFFileName = try restoreExamPDFIfNeeded(
                manifest: manifest,
                archiveDirectory: directory
            )
            let attempt = ExamAttempt(
                id: manifest.attemptID,
                sourceDocumentId: manifest.sourceDocumentID,
                sourceDocumentTitle: manifest.sourceDocumentTitle,
                sourceDocumentLocalFileName: manifest.sourceDocumentLocalFileName,
                sourceDocumentFingerprint: manifest.sourceDocumentFingerprint,
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
                    sourceDocumentId: manifest.sourceDocumentID,
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
                    sourceDocumentId: manifest.sourceDocumentID,
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
            restoredCount += 1
        }

        if restoredCount > 0 {
            try modelContext.saveOrRollbackIfNeeded()
        }
        return restoredCount
    }

    static func archiveBestEffort(
        attempt: ExamAttempt,
        drawings: [ExamHandwritingLayer] = [],
        gradeMarks: [ExamGradeMark] = []
    ) {
        do {
            try archive(attempt: attempt, drawings: drawings, gradeMarks: gradeMarks)
        } catch {
            assertionFailure("考试记录归档失败：\(error.localizedDescription)")
        }
    }

    static func archive(
        attempt: ExamAttempt,
        drawings: [ExamHandwritingLayer],
        gradeMarks: [ExamGradeMark]
    ) throws {
        let directory = archiveDirectory(for: attempt.id)
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
            version: 1,
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
            }
        )
        let data = try JSONEncoder.examArchive.encode(manifest)
        try data.write(to: directory.appendingPathComponent("manifest.json"), options: .atomic)
    }

    private static func archiveDirectory(for attemptID: UUID) -> URL {
        AppStorageDirectory.examArchives.appendingPathComponent(attemptID.uuidString, isDirectory: true)
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
