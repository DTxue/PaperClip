import Foundation
import UIKit

enum AppStorageDirectory {
    private static let root: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = support.appendingPathComponent("PaperClip", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static let pdfs = directory(named: "PDFs")
    static let cards = directory(named: "Cards")
    static let exports = directory(named: "Exports")

    private static func directory(named name: String) -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

enum StorageService {
    static func importPDF(from sourceURL: URL) throws -> (fileName: String, title: String) {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileName = "\(UUID().uuidString).pdf"
        let destination = AppStorageDirectory.pdfs.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        try makePDFReadOnly(at: destination)
        return (fileName, sourceURL.deletingPathExtension().lastPathComponent)
    }

    static func makePDFReadOnly(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444],
            ofItemAtPath: url.path
        )
    }

    static func saveCardImage(_ image: UIImage) throws -> String {
        let fileName = "\(UUID().uuidString).png"
        let destination = AppStorageDirectory.cards.appendingPathComponent(fileName)
        guard let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: destination, options: .atomic)
        return fileName
    }

    static func deleteFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
