import Foundation
import CryptoKit

extension StorageService {
    static func makePDFReadOnly(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444],
            ofItemAtPath: url.path
        )
    }

    static func deleteFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    static func deleteFile(_ storedFile: StoredFile) throws {
        try deleteFile(at: storedFile.url)
    }

    static func deleteFileBestEffort(at url: URL, context: String) {
        do {
            try deleteFile(at: url)
        } catch {
            assertionFailure("\(context)：\(error.localizedDescription)")
        }
    }

    static func deleteFileBestEffort(_ storedFile: StoredFile, context: String) {
        deleteFileBestEffort(at: storedFile.url, context: context)
    }

    static func deleteFiles(at urls: [URL]) throws {
        var firstError: Error?
        for url in urls {
            do {
                try deleteFile(at: url)
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }

    static func ensureParentDirectoryExists(for url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    static func sha256Fingerprint(for url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
