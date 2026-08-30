import Foundation

enum LegacyMistakeDataCleanup {
    private static let completionKey = "paperClip.legacyMistakeCleanup.v1.completed"
    private static let safetyBackupPathKey = "paperClip.legacyMistakeCleanup.v1.backupPath"

    /// Creates a recoverable snapshot before opening the persistent container,
    /// because opening it performs the V1 -> V2 destructive migration.
    @discardableResult
    static func prepareSafetyBackupIfNeeded(
        applicationSupport: URL = AppStorageDirectory.applicationSupport,
        outputRoot: URL? = nil,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) throws -> URL? {
        let legacyRoot = applicationSupport.appendingPathComponent("PaperClip", isDirectory: true)
        let legacyURLs = ["Cards", "Exports"].map {
            legacyRoot.appendingPathComponent($0, isDirectory: true)
        }
        let hasLegacyFiles = legacyURLs.contains { fileManager.fileExists(atPath: $0.path) }
        if defaults.bool(forKey: completionKey) && !hasLegacyFiles {
            return nil
        }

        if let path = defaults.string(forKey: safetyBackupPathKey) {
            let existingURL = URL(fileURLWithPath: path, isDirectory: true)
            if fileManager.fileExists(atPath: existingURL.path) {
                PaperClipDataBackupService.registerCompletedBackup(at: existingURL)
                return existingURL
            }
        }

        let storeURL = applicationSupport.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: storeURL.path) else {
            if hasLegacyFiles {
                throw CocoaError(.fileNoSuchFile)
            }
            return nil
        }

        let destinationRoot = outputRoot ?? fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LegacyMistakeCleanupSafetyBackup", isDirectory: true)
        let backupURL = try PaperClipDataBackupService.createBackup(
            applicationSupport: applicationSupport,
            temporaryDirectory: destinationRoot,
            persistentStoreURL: storeURL,
            now: .now
        )
        defaults.set(backupURL.path, forKey: safetyBackupPathKey)
        PaperClipDataBackupService.registerCompletedBackup(at: backupURL)
        return backupURL
    }

    static func removeLegacyFiles(
        at urls: [URL] = AppStorageDirectory.legacyMistakeDataURLs,
        fileManager: FileManager = .default
    ) throws {
        for url in urls where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    static func canRemoveLegacyFiles(
        at urls: [URL] = AppStorageDirectory.legacyMistakeDataURLs,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) -> Bool {
        let hasLegacyFiles = urls.contains { fileManager.fileExists(atPath: $0.path) }
        guard hasLegacyFiles else { return true }
        guard let path = defaults.string(forKey: safetyBackupPathKey) else { return false }
        return fileManager.fileExists(atPath: path)
    }

    static func markCompleted(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: completionKey)
    }

    static func isCompleted(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: completionKey)
    }
}
