import Foundation
import CryptoKit
import SQLite3

enum AppStorageDirectory {
    static let applicationSupport: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        createDirectoryIfNeeded(at: support)
        return support
    }()

    static let root: URL = {
        let support = applicationSupport
        let url = support.appendingPathComponent("PaperClip", isDirectory: true)
        createDirectoryIfNeeded(at: url)
        return url
    }()

    static let mistakeAttachments = directory(named: "MistakeAttachments")

    static var legacyMistakeDataURLs: [URL] {
        ["Cards", "Exports"].map { root.appendingPathComponent($0, isDirectory: true) }
    }

    private static func directory(named name: String) -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        createDirectoryIfNeeded(at: url)
        return url
    }

    private static func createDirectoryIfNeeded(at url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            assertionFailure("无法创建存储目录：\(error.localizedDescription)")
        }
    }
}

enum PaperClipBackupError: LocalizedError {
    case invalidBackup
    case pendingRestoreMissing
    case databaseSnapshotFailed(String)
    case unsupportedStorageItem(String)
    case restoreRollbackFailed(String)
    case backupFromNewerVersion

    var errorDescription: String? {
        switch self {
        case .invalidBackup:
            return "备份文件不完整、已损坏，或缺少 PaperClip 数据库。"
        case .pendingRestoreMissing:
            return "待恢复备份不存在，请重新选择备份文件。"
        case .databaseSnapshotFailed(let reason):
            return "数据库快照失败：\(reason)"
        case .unsupportedStorageItem(let path):
            return "备份目录包含不支持的文件类型：\(path)"
        case .restoreRollbackFailed(let path):
            return "恢复失败，原数据保存在 \(path)。为避免覆盖，当前启动不会打开持久数据库。"
        case .backupFromNewerVersion:
            return "该备份由更新版本的 PaperClip 创建。请先更新应用，再恢复此备份。"
        }
    }

    var preventsPersistentStoreOpening: Bool {
        if case .restoreRollbackFailed = self { return true }
        return false
    }
}

struct PaperClipBackupMetadata: Codable, Equatable {
    let formatVersion: Int
    let createdAt: Date
    let appVersion: String
    let buildVersion: String
}

struct PaperClipBackupManifest: Codable, Equatable {
    struct Entry: Codable, Equatable {
        let relativePath: String
        let byteCount: Int64
        let sha256: String
    }

    let formatVersion: Int
    let databaseRelativePath: String?
    let entries: [Entry]
}

enum PaperClipDataBackupService {
    static let backupFileExtension = "paperclipbackup"
    private static let pendingRestorePathKey = "paperClip.pendingRestorePath"
    private static let pendingBackupRequestKey = "paperClip.pendingBackupRequest"
    private static let completedBackupPathKey = "paperClip.completedBackupPath"

    static func createBackup(
        persistentStoreURL: URL,
        now: Date = .now
    ) throws -> URL {
        return try createBackup(
            applicationSupport: AppStorageDirectory.applicationSupport,
            temporaryDirectory: FileManager.default.temporaryDirectory,
            persistentStoreURL: persistentStoreURL,
            now: now
        )
    }

    static func createBackup(
        applicationSupport: URL,
        temporaryDirectory: URL,
        persistentStoreURL: URL,
        now: Date
    ) throws -> URL {
        let fileManager = FileManager.default
        let backupRoot = temporaryDirectory.appendingPathComponent("PaperClipBackups", isDirectory: true)
        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)

        let backupURL = backupRoot
            .appendingPathComponent(
                "PaperClip-\(backupTimestamp(for: now))-\(UUID().uuidString).\(backupFileExtension)",
                isDirectory: true
            )
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)

        do {
            let supportDestination = backupURL.appendingPathComponent("ApplicationSupport", isDirectory: true)
            let databaseRelativePath = try copyApplicationSupportSnapshot(
                from: applicationSupport,
                to: supportDestination,
                persistentStoreURL: persistentStoreURL
            )
            let manifest = PaperClipBackupManifest(
                formatVersion: 1,
                databaseRelativePath: databaseRelativePath,
                entries: try manifestEntries(in: supportDestination)
            )
            let manifestData = try JSONEncoder.paperClipBackupEncoder.encode(manifest)
            try manifestData.write(
                to: backupURL.appendingPathComponent("manifest.json"),
                options: .atomic
            )

            let metadata = PaperClipBackupMetadata(
                formatVersion: 2,
                createdAt: now,
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                buildVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
            )
            let metadataData = try JSONEncoder.paperClipBackupEncoder.encode(metadata)
            try metadataData.write(to: backupURL.appendingPathComponent("metadata.json"), options: .atomic)
            try validateBackup(at: backupURL)
            return backupURL
        } catch {
            try? fileManager.removeItem(at: backupURL)
            throw error
        }
    }

    static func stageRestore(from sourceURL: URL) throws {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard isValidBackup(at: sourceURL) else {
            throw PaperClipBackupError.invalidBackup
        }

        let fileManager = FileManager.default
        let stagingRoot = try pendingRestoreRoot()
        let stagedURL = stagingRoot.appendingPathComponent(
            "\(UUID().uuidString).\(backupFileExtension)",
            isDirectory: true
        )
        try fileManager.copyItem(at: sourceURL, to: stagedURL)
        guard isValidBackup(at: stagedURL) else {
            try? fileManager.removeItem(at: stagedURL)
            throw PaperClipBackupError.invalidBackup
        }
        let previousPath = UserDefaults.standard.string(forKey: pendingRestorePathKey)
        UserDefaults.standard.set(stagedURL.path, forKey: pendingRestorePathKey)
        if let previousPath, previousPath != stagedURL.path {
            try? fileManager.removeItem(at: URL(fileURLWithPath: previousPath))
        }
    }

    @discardableResult
    static func applyPendingRestoreIfNeeded() throws -> Bool {
        guard let path = UserDefaults.standard.string(forKey: pendingRestorePathKey) else {
            return false
        }

        let stagedURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: stagedURL.path) else {
            UserDefaults.standard.removeObject(forKey: pendingRestorePathKey)
            throw PaperClipBackupError.pendingRestoreMissing
        }

        try restore(
            from: stagedURL,
            to: AppStorageDirectory.applicationSupport,
            safeguardRoot: AppStorageDirectory.applicationSupport
                .deletingLastPathComponent()
                .appendingPathComponent("PaperClipRestoreSafeguards", isDirectory: true),
            now: .now
        )
        UserDefaults.standard.removeObject(forKey: pendingRestorePathKey)
        try? FileManager.default.removeItem(at: stagedURL)
        return true
    }

    static func restore(
        from backupURL: URL,
        to applicationSupport: URL,
        safeguardRoot: URL,
        now: Date,
        installRestoredSupport: ((URL, URL) throws -> Void)? = nil
    ) throws {
        let fileManager = FileManager.default
        try validateBackup(at: backupURL)
        let sourceSupport = backupURL.appendingPathComponent("ApplicationSupport", isDirectory: true)

        let parent = applicationSupport.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: safeguardRoot, withIntermediateDirectories: true)

        let restoreTemp = parent.appendingPathComponent(".PaperClipRestore-\(UUID().uuidString)", isDirectory: true)
        let liveRollback = parent.appendingPathComponent(".PaperClipLiveRollback-\(UUID().uuidString)", isDirectory: true)
        let safeguard = safeguardRoot
            .appendingPathComponent("PaperClipPreRestore-\(backupTimestamp(for: now))-\(UUID().uuidString)", isDirectory: true)

        try fileManager.copyItem(at: sourceSupport, to: restoreTemp)
        let hadLiveData = fileManager.fileExists(atPath: applicationSupport.path)
        if hadLiveData {
            try fileManager.copyItem(at: applicationSupport, to: safeguard)
            try fileManager.moveItem(at: applicationSupport, to: liveRollback)
        }

        do {
            if let installRestoredSupport {
                try installRestoredSupport(restoreTemp, applicationSupport)
            } else {
                try fileManager.moveItem(at: restoreTemp, to: applicationSupport)
            }
            if hadLiveData {
                try? fileManager.removeItem(at: liveRollback)
            }
        } catch {
            if hadLiveData, fileManager.fileExists(atPath: liveRollback.path) {
                do {
                    if fileManager.fileExists(atPath: applicationSupport.path) {
                        try fileManager.removeItem(at: applicationSupport)
                    }
                    try fileManager.moveItem(at: liveRollback, to: applicationSupport)
                } catch {
                    throw PaperClipBackupError.restoreRollbackFailed(liveRollback.path)
                }
            }
            throw error
        }
    }

    static func isValidBackup(at url: URL) -> Bool {
        do {
            try validateBackup(at: url)
            return true
        } catch {
            return false
        }
    }

    static func scheduleBackupOnNextLaunch() {
        UserDefaults.standard.set(true, forKey: pendingBackupRequestKey)
    }

    static func recoverInterruptedRestoreIfNeeded() throws {
        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        try recoverInterruptedRestoreIfNeeded(applicationSupport: applicationSupport)
    }

    static func recoverInterruptedRestoreIfNeeded(applicationSupport: URL) throws {
        let fileManager = FileManager.default
        let parent = applicationSupport.deletingLastPathComponent()
        let contents = (try? fileManager.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey]
        )) ?? []
        let rollbacks = contents.filter {
            $0.lastPathComponent.hasPrefix(".PaperClipLiveRollback-")
        }.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            return lhs > rhs
        }
        guard let newestRollback = rollbacks.first else { return }

        let liveContents = (try? fileManager.contentsOfDirectory(atPath: applicationSupport.path)) ?? []
        if !fileManager.fileExists(atPath: applicationSupport.path) || liveContents.isEmpty {
            do {
                if fileManager.fileExists(atPath: applicationSupport.path) {
                    try fileManager.removeItem(at: applicationSupport)
                }
                try fileManager.moveItem(at: newestRollback, to: applicationSupport)
            } catch {
                throw PaperClipBackupError.restoreRollbackFailed(newestRollback.path)
            }
        }

        let safeguardRoot = parent.appendingPathComponent("PaperClipRestoreSafeguards", isDirectory: true)
        try fileManager.createDirectory(at: safeguardRoot, withIntermediateDirectories: true)
        for rollback in rollbacks where fileManager.fileExists(atPath: rollback.path) {
            let destination = safeguardRoot.appendingPathComponent(
                "Interrupted-\(UUID().uuidString)",
                isDirectory: true
            )
            try? fileManager.moveItem(at: rollback, to: destination)
        }
    }

    @discardableResult
    static func createScheduledBackupIfNeeded() throws -> URL? {
        let applicationSupport = AppStorageDirectory.applicationSupport
        let outputRoot = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PaperClipGeneratedBackup", isDirectory: true)
        return try createScheduledBackupIfNeeded(
            applicationSupport: applicationSupport,
            outputRoot: outputRoot,
            now: .now
        )
    }

    static func createScheduledBackupIfNeeded(
        applicationSupport: URL,
        outputRoot: URL,
        now: Date
    ) throws -> URL? {
        guard UserDefaults.standard.bool(forKey: pendingBackupRequestKey) else {
            return nil
        }

        let storeURL = applicationSupport.appendingPathComponent("default.store")
        let previousBackupURL = completedBackupURL()
        let backupURL = try createBackup(
            applicationSupport: applicationSupport,
            temporaryDirectory: outputRoot,
            persistentStoreURL: storeURL,
            now: now
        )
        UserDefaults.standard.set(backupURL.path, forKey: completedBackupPathKey)
        UserDefaults.standard.removeObject(forKey: pendingBackupRequestKey)
        if let previousBackupURL, previousBackupURL != backupURL {
            try? FileManager.default.removeItem(at: previousBackupURL)
        }
        return backupURL
    }

    static func completedBackupURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: completedBackupPathKey) else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            UserDefaults.standard.removeObject(forKey: completedBackupPathKey)
            return nil
        }
        return url
    }

    static func registerCompletedBackup(at url: URL) {
        let previousBackupURL = completedBackupURL()
        UserDefaults.standard.set(url.path, forKey: completedBackupPathKey)
        if let previousBackupURL, previousBackupURL != url {
            try? FileManager.default.removeItem(at: previousBackupURL)
        }
    }

    static func clearPendingRestoreForTests() {
        UserDefaults.standard.removeObject(forKey: pendingRestorePathKey)
        UserDefaults.standard.removeObject(forKey: pendingBackupRequestKey)
        UserDefaults.standard.removeObject(forKey: completedBackupPathKey)
    }

    static func pendingRestoreURLForTests() -> URL? {
        UserDefaults.standard.string(forKey: pendingRestorePathKey).map(URL.init(fileURLWithPath:))
    }

    static func isBackupScheduledForTests() -> Bool {
        UserDefaults.standard.bool(forKey: pendingBackupRequestKey)
    }

    private static func pendingRestoreRoot() throws -> URL {
        let root = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PaperClipPendingRestore", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func recreateDirectory(at url: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static func validateBackup(at backupURL: URL) throws {
        let fileManager = FileManager.default
        let supportURL = backupURL.appendingPathComponent("ApplicationSupport", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: supportURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw PaperClipBackupError.invalidBackup
        }

        let metadataURL = backupURL.appendingPathComponent("metadata.json")
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder.paperClipBackupDecoder.decode(
                  PaperClipBackupMetadata.self,
                  from: metadataData
              ) else {
            throw PaperClipBackupError.invalidBackup
        }
        if let backupBuild = Int(metadata.buildVersion),
           let currentBuildText = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
           let currentBuild = Int(currentBuildText),
           backupBuild > currentBuild {
            throw PaperClipBackupError.backupFromNewerVersion
        }

        if metadata.formatVersion == 1 {
            try validateLegacyDatabase(in: supportURL)
            return
        }
        guard metadata.formatVersion == 2 else {
            throw PaperClipBackupError.invalidBackup
        }

        let manifestURL = backupURL.appendingPathComponent("manifest.json")
        guard let manifestData = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder.paperClipBackupDecoder.decode(
                  PaperClipBackupManifest.self,
                  from: manifestData
              ),
              manifest.formatVersion == 1,
              manifest.entries == (try? manifestEntries(in: supportURL)) else {
            throw PaperClipBackupError.invalidBackup
        }

        guard let databaseRelativePath = manifest.databaseRelativePath,
              isSafeRelativePath(databaseRelativePath),
              manifest.entries.contains(where: { $0.relativePath == databaseRelativePath }) else {
            throw PaperClipBackupError.invalidBackup
        }
        try validateSQLiteDatabase(
            at: supportURL.appendingPathComponent(databaseRelativePath)
        )
    }

    private static func copyApplicationSupportSnapshot(
        from source: URL,
        to destination: URL,
        persistentStoreURL: URL
    ) throws -> String {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        guard fileManager.fileExists(atPath: source.path) else {
            throw PaperClipBackupError.invalidBackup
        }

        let standardizedSource = source.standardizedFileURL
        let standardizedStore = persistentStoreURL.standardizedFileURL
        guard fileManager.fileExists(atPath: standardizedStore.path),
              let databaseRelativePath = relativePath(of: standardizedStore, within: standardizedSource) else {
            throw PaperClipBackupError.databaseSnapshotFailed("未找到 Application Support 中的数据库。")
        }
        let excludedPaths: Set<String> = [
            standardizedStore.path,
            standardizedStore.path + "-wal",
            standardizedStore.path + "-shm"
        ]

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: standardizedSource,
            includingPropertiesForKeys: resourceKeys,
            options: [],
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw PaperClipBackupError.invalidBackup
        }

        for case let itemURL as URL in enumerator {
            let standardizedItem = itemURL.standardizedFileURL
            if excludedPaths.contains(standardizedItem.path) {
                continue
            }
            guard let relativePath = relativePath(of: standardizedItem, within: standardizedSource) else {
                throw PaperClipBackupError.unsupportedStorageItem(itemURL.path)
            }
            let values = try standardizedItem.resourceValues(forKeys: Set(resourceKeys))
            if values.isSymbolicLink == true {
                throw PaperClipBackupError.unsupportedStorageItem(relativePath)
            }

            let targetURL = destination.appendingPathComponent(relativePath)
            if values.isDirectory == true {
                try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            } else if values.isRegularFile == true {
                try fileManager.createDirectory(
                    at: targetURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: standardizedItem, to: targetURL)
            } else {
                throw PaperClipBackupError.unsupportedStorageItem(relativePath)
            }
        }
        if let enumerationError {
            throw enumerationError
        }

        let destinationStore = destination.appendingPathComponent(databaseRelativePath)
        try fileManager.createDirectory(
            at: destinationStore.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try createSQLiteSnapshot(from: persistentStoreURL, to: destinationStore)
        return databaseRelativePath
    }

    private static func createSQLiteSnapshot(from sourceURL: URL, to destinationURL: URL) throws {
        var sourceDatabase: OpaquePointer?
        var destinationDatabase: OpaquePointer?
        let sourceFlags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let destinationFlags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX

        guard sqlite3_open_v2(sourceURL.path, &sourceDatabase, sourceFlags, nil) == SQLITE_OK,
              let sourceHandle = sourceDatabase else {
            let reason = sqliteErrorMessage(sourceDatabase)
            if let sourceDatabase { sqlite3_close(sourceDatabase) }
            throw PaperClipBackupError.databaseSnapshotFailed(reason)
        }
        defer { sqlite3_close(sourceHandle) }

        guard sqlite3_open_v2(destinationURL.path, &destinationDatabase, destinationFlags, nil) == SQLITE_OK,
              let destinationHandle = destinationDatabase else {
            let reason = sqliteErrorMessage(destinationDatabase)
            if let destinationDatabase { sqlite3_close(destinationDatabase) }
            throw PaperClipBackupError.databaseSnapshotFailed(reason)
        }
        defer {
            if let destinationDatabase {
                sqlite3_close(destinationDatabase)
            }
        }

        guard let backup = sqlite3_backup_init(destinationHandle, "main", sourceHandle, "main") else {
            throw PaperClipBackupError.databaseSnapshotFailed(sqliteErrorMessage(destinationHandle))
        }

        var result = SQLITE_OK
        var busyRetryCount = 0
        repeat {
            result = sqlite3_backup_step(backup, 128)
            if result == SQLITE_BUSY || result == SQLITE_LOCKED {
                busyRetryCount += 1
                sqlite3_sleep(10)
            }
        } while result == SQLITE_OK || (
            (result == SQLITE_BUSY || result == SQLITE_LOCKED) && busyRetryCount < 100
        )
        let finishResult = sqlite3_backup_finish(backup)
        guard result == SQLITE_DONE, finishResult == SQLITE_OK else {
            throw PaperClipBackupError.databaseSnapshotFailed(sqliteErrorMessage(destinationHandle))
        }

        guard sqlite3_exec(destinationHandle, "PRAGMA journal_mode=DELETE", nil, nil, nil) == SQLITE_OK else {
            throw PaperClipBackupError.databaseSnapshotFailed(sqliteErrorMessage(destinationHandle))
        }
        sqlite3_close(destinationHandle)
        destinationDatabase = nil
        try? FileManager.default.removeItem(
            at: URL(fileURLWithPath: destinationURL.path + "-wal")
        )
        try? FileManager.default.removeItem(
            at: URL(fileURLWithPath: destinationURL.path + "-shm")
        )
        try validateSQLiteDatabase(at: destinationURL)
    }

    private static func validateSQLiteDatabase(at url: URL) throws {
        try validateSQLiteDatabase(at: url, immutable: true)
    }

    private static func validateLegacyDatabase(in supportURL: URL) throws {
        let storeURL = supportURL.appendingPathComponent("default.store")
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            throw PaperClipBackupError.invalidBackup
        }
        try validateSQLiteDatabase(at: storeURL, immutable: false)
    }

    private static func validateSQLiteDatabase(at url: URL, immutable: Bool) throws {
        var database: OpaquePointer?
        let databasePath = immutable ? url.absoluteString + "?immutable=1" : url.path
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX | (immutable ? SQLITE_OPEN_URI : 0)
        guard sqlite3_open_v2(
            databasePath,
            &database,
            flags,
            nil
        ) == SQLITE_OK,
              let database else {
            let reason = sqliteErrorMessage(database)
            if let database { sqlite3_close(database) }
            throw PaperClipBackupError.databaseSnapshotFailed(reason)
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, "PRAGMA quick_check", -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PaperClipBackupError.databaseSnapshotFailed(sqliteErrorMessage(database))
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let result = sqlite3_column_text(statement, 0),
              String(cString: result) == "ok" else {
            throw PaperClipBackupError.databaseSnapshotFailed("数据库完整性检查未通过。")
        }
    }

    private static func sqliteErrorMessage(_ database: OpaquePointer?) -> String {
        guard let database, let message = sqlite3_errmsg(database) else {
            return "无法打开数据库。"
        }
        return String(cString: message)
    }

    private static func manifestEntries(in supportURL: URL) throws -> [PaperClipBackupManifest.Entry] {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [
            .fileSizeKey,
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: supportURL,
            includingPropertiesForKeys: resourceKeys,
            options: [],
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw PaperClipBackupError.invalidBackup
        }

        var entries: [PaperClipBackupManifest.Entry] = []
        for case let itemURL as URL in enumerator {
            guard let relativePath = relativePath(of: itemURL.standardizedFileURL, within: supportURL.standardizedFileURL),
                  isSafeRelativePath(relativePath) else {
                throw PaperClipBackupError.invalidBackup
            }
            let values = try itemURL.resourceValues(forKeys: Set(resourceKeys))
            if values.isSymbolicLink == true {
                throw PaperClipBackupError.invalidBackup
            }
            if values.isDirectory == true {
                continue
            }
            guard values.isRegularFile == true else {
                throw PaperClipBackupError.invalidBackup
            }
            entries.append(
                PaperClipBackupManifest.Entry(
                    relativePath: relativePath,
                    byteCount: Int64(values.fileSize ?? 0),
                    sha256: try sha256(of: itemURL)
                )
            )
        }
        if let enumerationError {
            throw enumerationError
        }
        return entries.sorted { $0.relativePath < $1.relativePath }
    }

    private static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func relativePath(of item: URL, within root: URL) -> String? {
        let rootPath = root.standardizedFileURL.path
        let itemPath = item.standardizedFileURL.path
        if itemPath == rootPath {
            return ""
        }
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard itemPath.hasPrefix(prefix) else { return nil }
        return String(itemPath.dropFirst(prefix.count))
    }

    private static func isSafeRelativePath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/") else { return false }
        return path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
            $0 != "." && $0 != ".." && !$0.isEmpty
        }
    }

    private static func backupTimestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}

private extension JSONEncoder {
    static var paperClipBackupEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var paperClipBackupDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
