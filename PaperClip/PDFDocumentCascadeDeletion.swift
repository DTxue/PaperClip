import Foundation
import SwiftData

enum PDFExamAttemptDeletionError: LocalizedError {
    case notInProgress
    case hasSubmittedPages

    var errorDescription: String? {
        switch self {
        case .notInProgress:
            return "只能删除进行中的考试记录。已交卷或已批阅的记录需要保留。"
        case .hasSubmittedPages:
            return "这次考试已有页面提交，必须完成整份 PDF，不能删除后重新开始。"
        }
    }
}

struct PDFDeletionArtifacts {
    let fileURLs: [URL]
    let archiveAttemptIDs: [UUID]

    static let empty = PDFDeletionArtifacts(fileURLs: [], archiveAttemptIDs: [])
}

struct PDFArchiveDeletionBatch {
    struct Move {
        let source: URL
        let staged: URL
    }

    let stagingRoot: URL?
    let moves: [Move]

    func rollback() throws {
        let fileManager = FileManager.default
        for move in moves.reversed() where fileManager.fileExists(atPath: move.staged.path) {
            guard !fileManager.fileExists(atPath: move.source.path) else {
                throw CocoaError(.fileWriteFileExists)
            }
            try fileManager.moveItem(at: move.staged, to: move.source)
        }
        if let stagingRoot, fileManager.fileExists(atPath: stagingRoot.path) {
            try fileManager.removeItem(at: stagingRoot)
        }
    }

    func finalize() {
        guard let stagingRoot else { return }
        try? FileManager.default.removeItem(at: stagingRoot)
    }
}

enum PDFArchiveDeletionFileStore {
    static let stagingPrefix = ".DeletionStaging-"

    static func stage(
        attemptIDs: [UUID],
        archiveRoot: URL
    ) throws -> PDFArchiveDeletionBatch {
        let fileManager = FileManager.default
        var stagingRoot: URL?
        var moves: [PDFArchiveDeletionBatch.Move] = []

        do {
            for attemptID in Set(attemptIDs) {
                let source = archiveRoot.appendingPathComponent(attemptID.uuidString, isDirectory: true)
                guard fileManager.fileExists(atPath: source.path) else { continue }

                if stagingRoot == nil {
                    let root = archiveRoot.appendingPathComponent(
                        "\(stagingPrefix)\(UUID().uuidString)",
                        isDirectory: true
                    )
                    try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
                    stagingRoot = root
                }
                guard let stagingRoot else { continue }
                let staged = stagingRoot.appendingPathComponent(attemptID.uuidString, isDirectory: true)
                try fileManager.moveItem(at: source, to: staged)
                moves.append(.init(source: source, staged: staged))
            }
            return PDFArchiveDeletionBatch(stagingRoot: stagingRoot, moves: moves)
        } catch {
            try? PDFArchiveDeletionBatch(stagingRoot: stagingRoot, moves: moves).rollback()
            throw error
        }
    }

    @discardableResult
    static func recoverInterruptedBatches(
        archiveRoot: URL,
        attemptExists: (UUID) throws -> Bool
    ) throws -> Int {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: archiveRoot.path) else { return 0 }
        let stagingRoots = try fileManager.contentsOfDirectory(
            at: archiveRoot,
            includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { url in
            url.lastPathComponent.hasPrefix(stagingPrefix)
                && (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }

        var recoveredCount = 0
        for stagingRoot in stagingRoots {
            let stagedArchives = try fileManager.contentsOfDirectory(
                at: stagingRoot,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            for stagedArchive in stagedArchives {
                guard let attemptID = UUID(uuidString: stagedArchive.lastPathComponent) else { continue }
                let liveArchive = archiveRoot
                    .appendingPathComponent(attemptID.uuidString, isDirectory: true)
                if try attemptExists(attemptID) {
                    if fileManager.fileExists(atPath: liveArchive.path) {
                        try fileManager.removeItem(at: stagedArchive)
                    } else {
                        try fileManager.moveItem(at: stagedArchive, to: liveArchive)
                        recoveredCount += 1
                    }
                } else {
                    try fileManager.removeItem(at: stagedArchive)
                }
            }
            if fileManager.fileExists(atPath: stagingRoot.path) {
                let remaining = try fileManager.contentsOfDirectory(atPath: stagingRoot.path)
                if remaining.isEmpty {
                    try fileManager.removeItem(at: stagingRoot)
                }
            }
        }
        return recoveredCount
    }
}

enum PDFArtifactDeletionError: LocalizedError {
    case archiveRollbackFailed(primary: String, rollback: String)

    var errorDescription: String? {
        switch self {
        case .archiveRollbackFailed(let primary, let rollback):
            return "删除未完成，且考试归档恢复失败。原错误：\(primary)；恢复错误：\(rollback)"
        }
    }
}

@MainActor
enum PDFArtifactDeletionTransaction {
    static func deleteInProgressExamAttempt(
        id attemptID: UUID,
        in modelContext: ModelContext,
        stageArchives: ([UUID]) throws -> PDFArchiveDeletionBatch
    ) throws -> [URL] {
        let plan = try modelContext.planInProgressExamAttemptDeletion(attemptID: attemptID)
        let archiveBatch = try stageArchives(plan.archiveAttemptIDs)
        do {
            let deleted = try modelContext.deleteInProgressExamAttemptCascade(attemptID: attemptID)
            archiveBatch.finalize()
            return deleted.fileURLs
        } catch {
            try rollback(archiveBatch, after: error)
        }
    }

    static func deletePDFDocument(
        id documentID: UUID,
        localFileURL: URL,
        in modelContext: ModelContext,
        stageArchives: ([UUID]) throws -> PDFArchiveDeletionBatch
    ) throws -> [URL] {
        let plan = try modelContext.planPDFDocumentDeletion(
            documentID: documentID,
            localFileURL: localFileURL
        )
        let archiveBatch = try stageArchives(plan.archiveAttemptIDs)
        do {
            let deleted = try modelContext.deletePDFDocumentCascade(
                documentID: documentID,
                localFileURL: localFileURL
            )
            try modelContext.saveOrRollbackIfNeeded()
            archiveBatch.finalize()
            return deleted.fileURLs
        } catch {
            try rollback(archiveBatch, after: error)
        }
    }

    private static func rollback(
        _ batch: PDFArchiveDeletionBatch,
        after primaryError: Error
    ) throws -> Never {
        do {
            try batch.rollback()
        } catch {
            throw PDFArtifactDeletionError.archiveRollbackFailed(
                primary: primaryError.localizedDescription,
                rollback: error.localizedDescription
            )
        }
        throw primaryError
    }
}

extension ModelContext {
    func planInProgressExamAttemptDeletion(
        attemptID: UUID
    ) throws -> PDFDeletionArtifacts {
        let attemptDescriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.id == attemptID
            }
        )
        guard let attempt = try fetchFirst(attemptDescriptor) else { return .empty }
        guard ExamAttemptStatus(rawValue: attempt.status) == .inProgress else {
            throw PDFExamAttemptDeletionError.notInProgress
        }
        guard try fetchExamPageSubmissions(attemptID: attemptID).isEmpty else {
            throw PDFExamAttemptDeletionError.hasSubmittedPages
        }
        let fileURLs = attempt.generatedPDFFileName.isEmpty
            ? []
            : [attempt.generatedPDFURL]
        return PDFDeletionArtifacts(
            fileURLs: fileURLs,
            archiveAttemptIDs: [attemptID]
        )
    }

    func planPDFDocumentDeletion(
        documentID: UUID,
        localFileURL: URL
    ) throws -> PDFDeletionArtifacts {
        let attempts = try fetchExamAttemptsForDocumentDeletion(
            documentID: documentID,
            localFileURL: localFileURL
        )
        var fileURLs = attempts
            .filter { !$0.generatedPDFFileName.isEmpty }
            .map(\.generatedPDFURL)
        fileURLs.append(localFileURL)
        return PDFDeletionArtifacts(
            fileURLs: fileURLs,
            archiveAttemptIDs: attempts.map(\.id)
        )
    }

    func deleteInProgressExamAttemptCascade(attemptID: UUID) throws -> PDFDeletionArtifacts {
        let deletionArtifacts = try planInProgressExamAttemptDeletion(attemptID: attemptID)
        guard !deletionArtifacts.archiveAttemptIDs.isEmpty else { return .empty }
        let attemptDescriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.id == attemptID
            }
        )
        guard let attempt = try fetchFirst(attemptDescriptor) else { return .empty }

        var handwritingDescriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            }
        )
        handwritingDescriptor.propertiesToFetch = ExamHandwritingLayer.deletionPropertiesToFetch
        try deleteFetched(handwritingDescriptor)

        var gradeMarkDescriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
            }
        )
        gradeMarkDescriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
        try deleteFetched(gradeMarkDescriptor)

        var pageSubmissionDescriptor = FetchDescriptor<ExamPageSubmission>(
            predicate: #Predicate<ExamPageSubmission> { submission in
                submission.attemptId == attemptID
            }
        )
        pageSubmissionDescriptor.propertiesToFetch = ExamPageSubmission.deletionPropertiesToFetch
        try deleteFetched(pageSubmissionDescriptor)

        delete(attempt)
        try saveOrRollbackIfNeeded()
        return deletionArtifacts
    }

    func deletePDFDocumentCascade(
        documentID: UUID,
        localFileURL: URL
    ) throws -> PDFDeletionArtifacts {
        let deletionArtifacts = try planPDFDocumentDeletion(
            documentID: documentID,
            localFileURL: localFileURL
        )
        let attempts = try fetchExamAttemptsForDocumentDeletion(
            documentID: documentID,
            localFileURL: localFileURL
        )
        var handwritingDescriptor = FetchDescriptor<HandwritingLayer>(
            predicate: #Predicate<HandwritingLayer> { layer in layer.documentId == documentID }
        )
        handwritingDescriptor.propertiesToFetch = HandwritingLayer.deletionPropertiesToFetch
        try deleteFetched(handwritingDescriptor)

        for attempt in attempts {
            let attemptID = attempt.id
            var examHandwritingDescriptor = FetchDescriptor<ExamHandwritingLayer>(
                predicate: #Predicate<ExamHandwritingLayer> { layer in
                    layer.attemptId == attemptID
                }
            )
            examHandwritingDescriptor.propertiesToFetch = ExamHandwritingLayer.deletionPropertiesToFetch
            try deleteFetched(examHandwritingDescriptor)

            var gradeMarkDescriptor = FetchDescriptor<ExamGradeMark>(
                predicate: #Predicate<ExamGradeMark> { mark in
                    mark.attemptId == attemptID
                }
            )
            gradeMarkDescriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
            try deleteFetched(gradeMarkDescriptor)

            var pageSubmissionDescriptor = FetchDescriptor<ExamPageSubmission>(
                predicate: #Predicate<ExamPageSubmission> { submission in
                    submission.attemptId == attemptID
                }
            )
            pageSubmissionDescriptor.propertiesToFetch = ExamPageSubmission.deletionPropertiesToFetch
            try deleteFetched(pageSubmissionDescriptor)
            delete(attempt)
        }

        if let document = try fetchPDFDocument(id: documentID) {
            delete(document)
        }

        return deletionArtifacts
    }

    private func fetchExamAttemptsForDocumentDeletion(
        documentID: UUID,
        localFileURL: URL
    ) throws -> [ExamAttempt] {
        let localFileName = localFileURL.lastPathComponent
        let hasLocalFileName = !localFileName.isEmpty
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (hasLocalFileName && attempt.sourceDocumentLocalFileName == localFileName)
            }
        )
        descriptor.propertiesToFetch = ExamAttempt.cascadeDeletionPropertiesToFetch
        return try fetch(descriptor)
    }
}
