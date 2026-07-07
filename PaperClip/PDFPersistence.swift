import Foundation
import SwiftData

extension ModelContext {
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
