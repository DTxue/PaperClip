import Foundation
import SQLite3

@main
enum PaperClipDataBackupServiceTests {
    static func main() throws {
        try testCreateBackupCopiesApplicationSupportAndMetadata()
        try testSQLiteSnapshotCapturesWALAndOmitsSidecars()
        try testCreatingAnotherBackupKeepsPreviousBackup()
        try testScheduledBackupRetriesAfterFailure()
        try testTamperedBackupIsRejected()
        try testBackupWithoutMetadataIsRejected()
        try testBackupWithoutDatabaseSnapshotIsRejected()
        try testLegacyBackupRequiresHealthyDatabase()
        try testInvalidNewRestoreDoesNotDiscardPendingRestore()
        try testRestoreReplacesApplicationSupportAndKeepsSafeguard()
        try testRestoreInstallationFailureRollsBackLiveData()
        try testInterruptedRestoreRecoversLiveDirectory()
        try testInvalidBackupIsRejected()

        print("PaperClipDataBackupServiceTests: 52 passed")
    }

    private static func testCreateBackupCopiesApplicationSupportAndMetadata() throws {
        let root = try makeTemporaryDirectory(named: "create")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        let paperClipPDFs = appSupport
            .appendingPathComponent("PaperClip", isDirectory: true)
            .appendingPathComponent("PDFs", isDirectory: true)
        try FileManager.default.createDirectory(at: paperClipPDFs, withIntermediateDirectories: true)
        let store = try makeSQLiteStore(at: appSupport.appendingPathComponent("default.store"))
        try Data("pdf".utf8).write(to: paperClipPDFs.appendingPathComponent("paper.pdf"))

        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: appSupport,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        expect(backup.pathExtension == PaperClipDataBackupService.backupFileExtension, "uses backup extension")
        expect(PaperClipDataBackupService.isValidBackup(at: backup), "backup is valid")
        expect(fileExists(backup.appendingPathComponent("metadata.json")), "writes metadata")
        expect(fileExists(backup.appendingPathComponent("manifest.json")), "writes integrity manifest")
        expect(fileExists(backup.appendingPathComponent("ApplicationSupport/default.store")), "copies store")
        expect(
            fileExists(backup.appendingPathComponent("ApplicationSupport/PaperClip/PDFs/paper.pdf")),
            "copies nested files"
        )
    }

    private static func testSQLiteSnapshotCapturesWALAndOmitsSidecars() throws {
        let root = try makeTemporaryDirectory(named: "sqlite-snapshot")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let store = appSupport.appendingPathComponent("default.store")

        var database: OpaquePointer?
        expect(sqlite3_open(store.path, &database) == SQLITE_OK, "opens source SQLite store")
        guard let database else { fatalError("Missing SQLite connection") }
        defer { sqlite3_close(database) }

        try executeSQL("PRAGMA journal_mode=WAL", in: database)
        try executeSQL("CREATE TABLE notes (value TEXT NOT NULL)", in: database)
        try executeSQL("INSERT INTO notes VALUES ('latest')", in: database)

        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: appSupport,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )
        let backupStore = backup.appendingPathComponent("ApplicationSupport/default.store")

        expect(sqliteText(at: backupStore, sql: "SELECT value FROM notes LIMIT 1") == "latest", "captures WAL data")
        expect(!fileExists(URL(fileURLWithPath: backupStore.path + "-wal")), "omits WAL sidecar")
        expect(!fileExists(URL(fileURLWithPath: backupStore.path + "-shm")), "omits SHM sidecar")
        expect(PaperClipDataBackupService.isValidBackup(at: backup), "SQLite snapshot validates")
    }

    private static func testCreatingAnotherBackupKeepsPreviousBackup() throws {
        let root = try makeTemporaryDirectory(named: "keep-previous")
        let support = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        let store = try makeSQLiteStore(at: support.appendingPathComponent("default.store"))
        let first = try PaperClipDataBackupService.createBackup(
            applicationSupport: support,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )
        let second = try PaperClipDataBackupService.createBackup(
            applicationSupport: support,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        expect(first != second, "uses unique backup package names")
        expect(fileExists(first), "keeps previous backup")
        expect(fileExists(second), "creates new backup")
    }

    private static func testScheduledBackupRetriesAfterFailure() throws {
        PaperClipDataBackupService.clearPendingRestoreForTests()
        defer { PaperClipDataBackupService.clearPendingRestoreForTests() }

        let root = try makeTemporaryDirectory(named: "scheduled-retry")
        let support = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        PaperClipDataBackupService.scheduleBackupOnNextLaunch()

        do {
            _ = try PaperClipDataBackupService.createScheduledBackupIfNeeded(
                applicationSupport: support,
                outputRoot: root.appendingPathComponent("Output", isDirectory: true),
                now: Date(timeIntervalSince1970: 1_804_291_200)
            )
            fatalError("Expected missing store failure")
        } catch {
            expect(PaperClipDataBackupService.isBackupScheduledForTests(), "keeps failed request pending")
        }

        _ = try makeSQLiteStore(at: support.appendingPathComponent("default.store"))
        let backup = try PaperClipDataBackupService.createScheduledBackupIfNeeded(
            applicationSupport: support,
            outputRoot: root.appendingPathComponent("Output", isDirectory: true),
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )
        expect(backup.map(fileExists) == true, "retries scheduled backup")
        expect(!PaperClipDataBackupService.isBackupScheduledForTests(), "clears request after success")
    }

    private static func testTamperedBackupIsRejected() throws {
        let root = try makeTemporaryDirectory(named: "tampered")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let store = try makeSQLiteStore(at: appSupport.appendingPathComponent("default.store"))
        let payload = appSupport.appendingPathComponent("PaperClip/PDFs/paper.pdf")
        try FileManager.default.createDirectory(
            at: payload.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("original".utf8).write(to: payload)

        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: appSupport,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )
        try Data("changed".utf8).write(
            to: backup.appendingPathComponent("ApplicationSupport/PaperClip/PDFs/paper.pdf")
        )

        expect(!PaperClipDataBackupService.isValidBackup(at: backup), "rejects tampered backup")
    }

    private static func testBackupWithoutMetadataIsRejected() throws {
        let root = try makeTemporaryDirectory(named: "missing-metadata")
        let backup = root.appendingPathComponent("NoMetadata.paperclipbackup", isDirectory: true)
        try FileManager.default.createDirectory(
            at: backup.appendingPathComponent("ApplicationSupport", isDirectory: true),
            withIntermediateDirectories: true
        )

        expect(!PaperClipDataBackupService.isValidBackup(at: backup), "requires backup metadata")
    }

    private static func testBackupWithoutDatabaseSnapshotIsRejected() throws {
        let root = try makeTemporaryDirectory(named: "missing-database")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let store = try makeSQLiteStore(at: appSupport.appendingPathComponent("default.store"))
        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: appSupport,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        let manifestURL = backup.appendingPathComponent("manifest.json")
        let decoder = JSONDecoder()
        let original = try decoder.decode(
            PaperClipBackupManifest.self,
            from: Data(contentsOf: manifestURL)
        )
        let invalid = PaperClipBackupManifest(
            formatVersion: original.formatVersion,
            databaseRelativePath: nil,
            entries: original.entries
        )
        let encoder = JSONEncoder()
        try encoder.encode(invalid).write(to: manifestURL, options: .atomic)

        expect(!PaperClipDataBackupService.isValidBackup(at: backup), "requires database snapshot")
    }

    private static func testLegacyBackupRequiresHealthyDatabase() throws {
        let root = try makeTemporaryDirectory(named: "legacy")
        let backup = root.appendingPathComponent("Legacy.paperclipbackup", isDirectory: true)
        let support = backup.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        _ = try makeSQLiteStore(at: support.appendingPathComponent("default.store"))
        try writeLegacyMetadata(to: backup)

        expect(PaperClipDataBackupService.isValidBackup(at: backup), "accepts healthy v1 backup")
        try Data("broken".utf8).write(to: support.appendingPathComponent("default.store"))
        expect(!PaperClipDataBackupService.isValidBackup(at: backup), "rejects corrupt v1 database")
    }

    private static func testInvalidNewRestoreDoesNotDiscardPendingRestore() throws {
        PaperClipDataBackupService.clearPendingRestoreForTests()
        defer { PaperClipDataBackupService.clearPendingRestoreForTests() }

        let root = try makeTemporaryDirectory(named: "preserve-pending")
        let support = root.appendingPathComponent("Source", isDirectory: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let store = try makeSQLiteStore(at: support.appendingPathComponent("default.store"))
        let validBackup = try PaperClipDataBackupService.createBackup(
            applicationSupport: support,
            temporaryDirectory: root,
            persistentStoreURL: store,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )
        try PaperClipDataBackupService.stageRestore(from: validBackup)
        let originalPending = PaperClipDataBackupService.pendingRestoreURLForTests()

        let invalidBackup = root.appendingPathComponent("Invalid.paperclipbackup", isDirectory: true)
        try FileManager.default.createDirectory(at: invalidBackup, withIntermediateDirectories: true)
        do {
            try PaperClipDataBackupService.stageRestore(from: invalidBackup)
            fatalError("Expected invalid restore to fail")
        } catch PaperClipBackupError.invalidBackup {
            expect(PaperClipDataBackupService.pendingRestoreURLForTests() == originalPending, "keeps pending path")
            expect(originalPending.map(fileExists) == true, "keeps pending package")
        }
    }

    private static func testRestoreReplacesApplicationSupportAndKeepsSafeguard() throws {
        let root = try makeTemporaryDirectory(named: "restore")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: appSupport.appendingPathComponent("old.store"))

        let sourceSupport = root.appendingPathComponent("BackupSource", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceSupport, withIntermediateDirectories: true)
        let sourceStore = try makeSQLiteStore(at: sourceSupport.appendingPathComponent("default.store"))
        try Data("new".utf8).write(to: sourceSupport.appendingPathComponent("new.marker"))
        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: sourceSupport,
            temporaryDirectory: root.appendingPathComponent("BackupTemporary", isDirectory: true),
            persistentStoreURL: sourceStore,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        let safeguardRoot = root.appendingPathComponent("Caches", isDirectory: true)
        try PaperClipDataBackupService.restore(
            from: backup,
            to: appSupport,
            safeguardRoot: safeguardRoot,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        expect(fileExists(appSupport.appendingPathComponent("new.marker")), "restores backup file")
        expect(!fileExists(appSupport.appendingPathComponent("old.store")), "removes previous live data")
        expect(safeguardContains(fileName: "old.store", in: safeguardRoot), "keeps safeguard copy")
    }

    private static func testRestoreInstallationFailureRollsBackLiveData() throws {
        let root = try makeTemporaryDirectory(named: "restore-rollback")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: appSupport.appendingPathComponent("old.marker"))

        let sourceSupport = root.appendingPathComponent("BackupSource", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceSupport, withIntermediateDirectories: true)
        let sourceStore = try makeSQLiteStore(at: sourceSupport.appendingPathComponent("default.store"))
        let backup = try PaperClipDataBackupService.createBackup(
            applicationSupport: sourceSupport,
            temporaryDirectory: root.appendingPathComponent("BackupTemporary", isDirectory: true),
            persistentStoreURL: sourceStore,
            now: Date(timeIntervalSince1970: 1_804_291_200)
        )

        do {
            try PaperClipDataBackupService.restore(
                from: backup,
                to: appSupport,
                safeguardRoot: root.appendingPathComponent("Safeguards", isDirectory: true),
                now: Date(timeIntervalSince1970: 1_804_291_200),
                installRestoredSupport: { _, _ in throw TestError.installation }
            )
            fatalError("Expected installation failure")
        } catch TestError.installation {
            expect(fileExists(appSupport.appendingPathComponent("old.marker")), "rolls live data back")
        }
    }

    private static func testInterruptedRestoreRecoversLiveDirectory() throws {
        let root = try makeTemporaryDirectory(named: "interrupted-restore")
        let appSupport = root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let rollback = root.appendingPathComponent(
            ".PaperClipLiveRollback-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: rollback, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: rollback.appendingPathComponent("old.marker"))

        try PaperClipDataBackupService.recoverInterruptedRestoreIfNeeded(
            applicationSupport: appSupport
        )

        expect(fileExists(appSupport.appendingPathComponent("old.marker")), "recovers rollback data")
        expect(!fileExists(rollback), "consumes rollback directory")
    }

    private static func testInvalidBackupIsRejected() throws {
        let root = try makeTemporaryDirectory(named: "invalid")
        let backup = root.appendingPathComponent("Broken.paperclipbackup", isDirectory: true)
        try FileManager.default.createDirectory(at: backup, withIntermediateDirectories: true)

        do {
            try PaperClipDataBackupService.restore(
                from: backup,
                to: root.appendingPathComponent("ApplicationSupport", isDirectory: true),
                safeguardRoot: root.appendingPathComponent("Caches", isDirectory: true),
                now: Date(timeIntervalSince1970: 1_804_291_200)
            )
            fatalError("Expected invalid backup to throw")
        } catch PaperClipBackupError.invalidBackup {
            expect(true, "throws invalid backup")
        }
    }

    private static func makeTemporaryDirectory(named name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PaperClipDataBackupServiceTests-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private static func safeguardContains(fileName: String, in root: URL) -> Bool {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents.contains { fileExists($0.appendingPathComponent(fileName)) }
    }

    private static func executeSQL(_ sql: String, in database: OpaquePointer) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(errorMessage)
            throw TestError.sqlite(message)
        }
    }

    @discardableResult
    private static func makeSQLiteStore(at url: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var database: OpaquePointer?
        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            throw TestError.sqlite("Cannot create store")
        }
        defer { sqlite3_close(database) }
        try executeSQL("CREATE TABLE IF NOT EXISTS records (value TEXT)", in: database)
        try executeSQL("INSERT INTO records VALUES ('saved')", in: database)
        return url
    }

    private static func writeLegacyMetadata(to backup: URL) throws {
        let metadata = PaperClipBackupMetadata(
            formatVersion: 1,
            createdAt: Date(timeIntervalSince1970: 1_804_291_200),
            appVersion: "1.0",
            buildVersion: "1"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(metadata).write(
            to: backup.appendingPathComponent("metadata.json"),
            options: .atomic
        )
    }

    private static func sqliteText(at url: URL, sql: String) -> String? {
        var database: OpaquePointer?
        let immutableURL = url.absoluteString + "?immutable=1"
        guard sqlite3_open_v2(
            immutableURL,
            &database,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_URI,
            nil
        ) == SQLITE_OK,
              let database else {
            return nil
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let text = sqlite3_column_text(statement, 0) else {
            return nil
        }
        return String(cString: text)
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}

private enum TestError: Error {
    case sqlite(String)
    case installation
}
