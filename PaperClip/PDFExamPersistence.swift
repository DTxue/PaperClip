import Foundation
import SwiftData

extension ModelContext {
    func repairAllExamAttemptLinks() throws {
        let documents = try fetch(FetchDescriptor<PDFDocumentItem>())
        for document in documents {
            try repairExamAttemptLinks(for: document)
        }
    }

    func repairExamAttemptLinks(for document: PDFDocumentItem) throws {
        var didChange = false
        if document.fileFingerprint.isEmpty,
           let fingerprint = try? StorageService.sha256Fingerprint(for: document.localFileURL) {
            document.fileFingerprint = fingerprint
            didChange = true
        }

        let documentID = document.id
        let localFileName = document.localFileName
        let fingerprint = document.fileFingerprint
        let title = document.title
        let descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
                    || (!fingerprint.isEmpty && attempt.sourceDocumentFingerprint == fingerprint)
                    || (
                        attempt.sourceDocumentLocalFileName.isEmpty
                            && attempt.sourceDocumentFingerprint.isEmpty
                            && attempt.sourceDocumentTitle == title
                    )
            }
        )
        for attempt in try fetch(descriptor) {
            if attempt.sourceDocumentId != documentID {
                attempt.sourceDocumentId = documentID
                didChange = true
            }
            if attempt.sourceDocumentLocalFileName != localFileName {
                attempt.sourceDocumentLocalFileName = localFileName
                didChange = true
            }
            if attempt.sourceDocumentFingerprint != fingerprint {
                attempt.sourceDocumentFingerprint = fingerprint
                didChange = true
            }
            if attempt.sourceDocumentTitle != title {
                attempt.sourceDocumentTitle = title
                didChange = true
            }
        }

        if didChange {
            try saveOrRollbackIfNeeded()
        }
    }

    func fetchExamAttempt(id: UUID) throws -> ExamAttempt? {
        let descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchLatestExamAttempt(
        document: PDFDocumentItem,
        propertiesToFetch: [PartialKeyPath<ExamAttempt>] = []
    ) throws -> ExamAttempt? {
        let documentID = document.id
        let localFileName = document.localFileName
        let fingerprint = document.fileFingerprint
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
                    || (!fingerprint.isEmpty && attempt.sourceDocumentFingerprint == fingerprint)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetchFirst(descriptor)
    }

    func fetchExamAttempts(
        document: PDFDocumentItem,
        propertiesToFetch: [PartialKeyPath<ExamAttempt>] = []
    ) throws -> [ExamAttempt] {
        let documentID = document.id
        let localFileName = document.localFileName
        let fingerprint = document.fileFingerprint
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
                    || (!fingerprint.isEmpty && attempt.sourceDocumentFingerprint == fingerprint)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchExamAttemptCount(document: PDFDocumentItem) throws -> Int {
        let documentID = document.id
        let localFileName = document.localFileName
        let fingerprint = document.fileFingerprint
        return try fetchCount(FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
                    || (!fingerprint.isEmpty && attempt.sourceDocumentFingerprint == fingerprint)
            }
        ))
    }

    func fetchExamHandwritingLayers(
        attemptID: UUID,
        propertiesToFetch: [PartialKeyPath<ExamHandwritingLayer>] = []
    ) throws -> [ExamHandwritingLayer] {
        var descriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    @discardableResult
    func deleteExamHandwritingLayers(attemptID: UUID) throws -> Int {
        var descriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in
                layer.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = ExamHandwritingLayer.deletionPropertiesToFetch
        return try deleteFetched(descriptor)
    }

    func fetchExamGradeMarks(
        attemptID: UUID,
        propertiesToFetch: [PartialKeyPath<ExamGradeMark>] = []
    ) throws -> [ExamGradeMark] {
        var descriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    @discardableResult
    func deleteExamGradeMarks(attemptID: UUID) throws -> Int {
        var descriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
        return try deleteFetched(descriptor)
    }
}
