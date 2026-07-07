import Foundation
import SwiftData

extension ModelContext {
    func deletePDFDocumentCascade(documentID: UUID, localFileURL: URL) throws -> [URL] {
        var attemptDescriptor = FetchDescriptor<ExamAttempt>(
            predicate: #Predicate<ExamAttempt> { attempt in
                attempt.sourceDocumentId == documentID
            }
        )
        attemptDescriptor.propertiesToFetch = ExamAttempt.cascadeDeletionPropertiesToFetch
        let attempts = try fetch(attemptDescriptor)
        var fileURLsToDelete = attempts
            .filter { !$0.generatedPDFFileName.isEmpty }
            .map(\.generatedPDFURL)
        fileURLsToDelete.append(localFileURL)

        var handwritingDescriptor = FetchDescriptor<HandwritingLayer>(
            predicate: #Predicate<HandwritingLayer> { layer in layer.documentId == documentID }
        )
        handwritingDescriptor.propertiesToFetch = HandwritingLayer.deletionPropertiesToFetch
        try deleteFetched(handwritingDescriptor)

        var examHandwritingDescriptor = FetchDescriptor<ExamHandwritingLayer>(
            predicate: #Predicate<ExamHandwritingLayer> { layer in layer.sourceDocumentId == documentID }
        )
        examHandwritingDescriptor.propertiesToFetch = ExamHandwritingLayer.deletionPropertiesToFetch
        try deleteFetched(examHandwritingDescriptor)

        var gradeMarkDescriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in mark.sourceDocumentId == documentID }
        )
        gradeMarkDescriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
        try deleteFetched(gradeMarkDescriptor)

        for attempt in attempts {
            delete(attempt)
        }

        if let document = try fetchPDFDocument(id: documentID) {
            delete(document)
        }

        return fileURLsToDelete
    }
}
