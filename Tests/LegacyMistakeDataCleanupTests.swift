import Foundation

@main
enum LegacyMistakeDataCleanupTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyMistakeDataCleanupTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let cards = root.appendingPathComponent("Cards", isDirectory: true)
        let exports = root.appendingPathComponent("Exports", isDirectory: true)
        let current = root.appendingPathComponent("MistakeAttachments", isDirectory: true)
        let pdfs = root.appendingPathComponent("PDFs", isDirectory: true)
        for directory in [cards, exports, current, pdfs] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("fixture".utf8).write(to: directory.appendingPathComponent("fixture.data"))
        }

        try LegacyMistakeDataCleanup.removeLegacyFiles(at: [cards, exports])
        expect(!exists(cards), "removes legacy Cards directory")
        expect(!exists(exports), "removes legacy Exports directory")
        expect(exists(current), "keeps independent mistake attachments")
        expect(exists(pdfs), "keeps source PDFs")

        try LegacyMistakeDataCleanup.removeLegacyFiles(at: [cards, exports])
        expect(exists(current), "cleanup is idempotent")

        let suiteName = "LegacyMistakeDataCleanupTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        expect(!LegacyMistakeDataCleanup.isCompleted(defaults: defaults), "starts pending")
        LegacyMistakeDataCleanup.markCompleted(defaults: defaults)
        expect(LegacyMistakeDataCleanup.isCompleted(defaults: defaults), "persists completion")

        let unsafeSupport = root.appendingPathComponent("UnsafeSupport", isDirectory: true)
        let orphanedCards = unsafeSupport
            .appendingPathComponent("PaperClip", isDirectory: true)
            .appendingPathComponent("Cards", isDirectory: true)
        try FileManager.default.createDirectory(at: orphanedCards, withIntermediateDirectories: true)
        try Data("legacy".utf8).write(to: orphanedCards.appendingPathComponent("question.jpg"))
        let unsafeDefaultsName = "LegacyMistakeDataCleanupUnsafeTests-\(UUID().uuidString)"
        let unsafeDefaults = UserDefaults(suiteName: unsafeDefaultsName)!
        defer { unsafeDefaults.removePersistentDomain(forName: unsafeDefaultsName) }
        do {
            try LegacyMistakeDataCleanup.prepareSafetyBackupIfNeeded(
                applicationSupport: unsafeSupport,
                outputRoot: root.appendingPathComponent("Backups", isDirectory: true),
                defaults: unsafeDefaults
            )
            fatalError("legacy files without a database must block cleanup")
        } catch {}
        expect(
            FileManager.default.fileExists(atPath: orphanedCards.path),
            "keeps legacy files when no complete backup can be created"
        )

        print("LegacyMistakeDataCleanupTests: 9 passed")
    }

    private static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
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
