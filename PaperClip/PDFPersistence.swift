import Foundation
import SwiftData

extension ModelContext {
    func fetchRecoverablePDFDocument(
        sourceDocumentID: UUID,
        localFileName: String,
        fingerprint: String
    ) throws -> PDFDocumentItem? {
        if let exactDocument = try fetchPDFDocument(id: sourceDocumentID) {
            return exactDocument
        }

        if !localFileName.isEmpty {
            return try fetchFirst(FetchDescriptor<PDFDocumentItem>(
                predicate: #Predicate<PDFDocumentItem> { document in
                    document.localFileName == localFileName
                }
            ))
        }

        guard !fingerprint.isEmpty else { return nil }
        var descriptor = FetchDescriptor<PDFDocumentItem>(
            predicate: #Predicate<PDFDocumentItem> { document in
                document.fileFingerprint == fingerprint
            }
        )
        descriptor.fetchLimit = 2
        let matches = try fetch(descriptor)
        return matches.count == 1 ? matches[0] : nil
    }

    func fetchPDFDocument(id: UUID) throws -> PDFDocumentItem? {
        let descriptor = FetchDescriptor<PDFDocumentItem>(
            predicate: #Predicate<PDFDocumentItem> { document in document.id == id }
        )
        return try fetchFirst(descriptor)
    }

    func fetchPDFDocuments(
        subject: String,
        propertiesToFetch: [PartialKeyPath<PDFDocumentItem>] = []
    ) throws -> [PDFDocumentItem] {
        var descriptor = FetchDescriptor<PDFDocumentItem>(
            predicate: #Predicate<PDFDocumentItem> { document in
                document.subject == subject
            },
            sortBy: [SortDescriptor(\.lastOpenDate, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchPDFDocuments(
        subject: String?,
        propertiesToFetch: [PartialKeyPath<PDFDocumentItem>] = []
    ) throws -> [PDFDocumentItem] {
        if let subject {
            return try fetchPDFDocuments(subject: subject, propertiesToFetch: propertiesToFetch)
        }
        var descriptor = FetchDescriptor<PDFDocumentItem>(
            sortBy: [SortDescriptor(\.lastOpenDate, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

}
