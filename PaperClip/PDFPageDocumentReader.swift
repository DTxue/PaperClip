import CoreGraphics
import Foundation
@preconcurrency import PDFKit
#if canImport(UIKit)
import UIKit
#endif

enum PDFDocumentReader {
    static func document(at documentURL: URL) -> PDFDocument? {
        PDFDocument(url: documentURL)
    }

    static func requireDocument(at documentURL: URL) throws -> PDFDocument {
        guard let document = document(at: documentURL) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return document
    }
}

enum PDFPageDocumentReader {
    static func pageCount(in documentURL: URL) -> Int {
        PDFDocumentReader.document(at: documentURL)?.pageCount ?? 0
    }

    static func pageCount(at documentURL: URL) async -> Int {
        await Task.detached(priority: .userInitiated) {
            pageCount(in: documentURL)
        }.value
    }

    #if canImport(UIKit)
    static func pageThumbnail(
        at documentURL: URL,
        index: Int,
        size: CGSize
    ) -> UIImage? {
        guard let document = PDFDocumentReader.document(at: documentURL),
              let page = document.page(at: index) else { return nil }
        return page.thumbnail(of: size, for: .mediaBox)
    }

    static func pageThumbnail(
        at documentURL: URL,
        index: Int,
        size: CGSize
    ) async -> UIImage? {
        await Task.detached(priority: .utility) {
            pageThumbnail(at: documentURL, index: index, size: size)
        }.value
    }
    #endif
}
