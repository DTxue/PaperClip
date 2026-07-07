import Foundation
import UIKit
@preconcurrency import PDFKit

enum StorageService {
    static func importPDF(from sourceURL: URL) throws -> (fileName: String, title: String) {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileName = "\(UUID().uuidString).pdf"
        let destination = StoredFile.importedPDF(fileName: fileName).url
        try ensureParentDirectoryExists(for: destination)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        try makePDFReadOnly(at: destination)
        return (fileName, sourceURL.deletingPathExtension().lastPathComponent)
    }

    static func createExamPDF(from sourceURL: URL, selectedPageIndices: [Int]) throws -> String {
        let source = try PDFRenderSupport.document(at: sourceURL)
        guard let uniqueIndices = PDFPageExportSelectionSupport.sortedUniqueIndices(
            selectedPageIndices,
            maximumCount: source.pageCount,
            pageCount: source.pageCount
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let output = PDFDocument()
        for (outputIndex, sourceIndex) in uniqueIndices.enumerated() {
            guard let page = source.page(at: sourceIndex)?.copy() as? PDFPage else { continue }
            output.insert(page, at: outputIndex)
        }
        guard output.pageCount > 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let fileName = "\(UUID().uuidString).pdf"
        let destination = StoredFile.examPDF(fileName: fileName).url
        try ensureParentDirectoryExists(for: destination)
        guard output.write(to: destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try makePDFReadOnly(at: destination)
        return fileName
    }

    static func saveCardImage(_ image: UIImage) throws -> String {
        guard let data = ImageJPEGEncoder.standardData(from: image) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return try saveCardImageData(data)
    }

    static func saveCardImage(
        _ image: UIImage,
        priority: TaskPriority = .userInitiated
    ) async throws -> String {
        try await Task.detached(priority: priority) {
            try saveCardImage(image)
        }.value
    }

    static func saveCardImageData(_ data: Data) throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let destination = StoredFile.cardImage(fileName: fileName).url
        try ensureParentDirectoryExists(for: destination)
        try data.write(to: destination, options: .atomic)
        return fileName
    }
}
