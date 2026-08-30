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
        let directDescriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
            }
        )
        var attemptsByID = Dictionary(
            uniqueKeysWithValues: try fetch(directDescriptor).map { ($0.id, $0) }
        )

        if !fingerprint.isEmpty {
            let matchingDocumentCount = try fetchCount(FetchDescriptor<PDFDocumentItem>(
                predicate: #Predicate<PDFDocumentItem> { candidate in
                    candidate.fileFingerprint == fingerprint
                }
            ))
            if matchingDocumentCount == 1 {
                let legacyFingerprintDescriptor = FetchDescriptor<ExamAttempt>(
                    predicate: #Predicate<ExamAttempt> { attempt in
                        attempt.sourceDocumentLocalFileName.isEmpty
                            && attempt.sourceDocumentFingerprint == fingerprint
                    }
                )
                for attempt in try fetch(legacyFingerprintDescriptor) {
                    attemptsByID[attempt.id] = attempt
                }
            }
        }

        let matchingTitleCount = try fetchCount(FetchDescriptor<PDFDocumentItem>(
            predicate: #Predicate<PDFDocumentItem> { candidate in
                candidate.title == title
            }
        ))
        if matchingTitleCount == 1 {
            let legacyTitleDescriptor = FetchDescriptor<ExamAttempt>(
                predicate: #Predicate<ExamAttempt> { attempt in
                    attempt.sourceDocumentLocalFileName.isEmpty
                        && attempt.sourceDocumentFingerprint.isEmpty
                        && attempt.sourceDocumentTitle == title
                }
            )
            for attempt in try fetch(legacyTitleDescriptor) {
                attemptsByID[attempt.id] = attempt
            }
        }

        for attempt in attemptsByID.values {
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
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetchFirst(descriptor)
    }

    func fetchCurrentExamAttempt(
        document: PDFDocumentItem,
        propertiesToFetch: [PartialKeyPath<ExamAttempt>] = []
    ) throws -> ExamAttempt? {
        let documentID = document.id
        let localFileName = document.localFileName
        let inProgressStatus = ExamAttemptStatus.inProgress.rawValue
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                (attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName))
                    && attempt.status == inProgressStatus
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetchFirst(descriptor)
    }

    func fetchResumableFullDocumentExamAttempt(
        document: PDFDocumentItem,
        sourcePageCount: Int,
        propertiesToFetch: [PartialKeyPath<ExamAttempt>] = []
    ) throws -> ExamAttempt? {
        guard sourcePageCount > 0 else { return nil }
        let documentID = document.id
        let localFileName = document.localFileName
        let requiredPageIndices = Array(0..<sourcePageCount)
        let inProgressStatus = ExamAttemptStatus.inProgress.rawValue
        let submittedStatus = ExamAttemptStatus.submitted.rawValue
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                (attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName))
                    && (attempt.status == inProgressStatus || attempt.status == submittedStatus)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch

        for attempt in try fetch(descriptor) {
            guard attempt.selectedPageIndices == requiredPageIndices else { continue }
            if ExamAttemptStatus(rawValue: attempt.status) == .inProgress {
                return attempt
            }
            let submissions = try fetchExamPageSubmissions(attemptID: attempt.id)
            if submissions.contains(where: {
                $0.status == ExamPageSubmissionStatus.submitted.rawValue
            }) {
                return attempt
            }
        }
        return nil
    }

    func fetchExamAttempts(
        document: PDFDocumentItem,
        propertiesToFetch: [PartialKeyPath<ExamAttempt>] = []
    ) throws -> [ExamAttempt] {
        let documentID = document.id
        let localFileName = document.localFileName
        var descriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchExamAttemptCount(document: PDFDocumentItem) throws -> Int {
        let documentID = document.id
        let localFileName = document.localFileName
        return try fetchCount(FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
                    || (!localFileName.isEmpty && attempt.sourceDocumentLocalFileName == localFileName)
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
