import Foundation

@main
enum MistakeAttachmentStoreTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MistakeAttachmentStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let original = Data([0x00, 0x11, 0x22, 0xFF])
        let fileName = try MistakeAttachmentStore.save(
            data: original,
            preferredExtension: "HEIC",
            directory: directory
        )
        expect(fileName.hasSuffix(".heic"), "preserves a safe original extension")
        let stored = try Data(contentsOf: directory.appendingPathComponent(fileName))
        expect(stored == original, "stores the original bytes unchanged")

        try MistakeAttachmentStore.remove(fileName: fileName, directory: directory)
        expect(
            !FileManager.default.fileExists(atPath: directory.appendingPathComponent(fileName).path),
            "removes the requested attachment"
        )
        try MistakeAttachmentStore.remove(fileName: fileName, directory: directory)

        let sanitized = try MistakeAttachmentStore.save(
            data: original,
            preferredExtension: "../bad extension",
            directory: directory
        )
        expect(!sanitized.contains("/"), "sanitizes unsafe extensions")

        let protectedDirectory = directory.appendingPathComponent("PDFs", isDirectory: true)
        try FileManager.default.createDirectory(at: protectedDirectory, withIntermediateDirectories: true)
        let protectedFile = protectedDirectory.appendingPathComponent("source.pdf")
        try original.write(to: protectedFile)
        do {
            try MistakeAttachmentStore.remove(
                fileName: "../PDFs/source.pdf",
                directory: directory
            )
            fatalError("path traversal must be rejected")
        } catch {}
        expect(FileManager.default.fileExists(atPath: protectedFile.path), "keeps files outside the attachment directory")

        let stagedName = try MistakeAttachmentStore.save(
            data: original,
            preferredExtension: "png",
            directory: directory
        )
        let staged = try MistakeAttachmentStore.stageForDeletion(
            fileNames: [stagedName],
            directory: directory
        )
        expect(
            !FileManager.default.fileExists(atPath: directory.appendingPathComponent(stagedName).path),
            "staging hides the file before database deletion"
        )
        try staged.rollback()
        expect(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent(stagedName).path),
            "rollback restores a staged file"
        )

        let referencedName = try MistakeAttachmentStore.save(
            data: original,
            preferredExtension: "png",
            directory: directory
        )
        let deletedName = try MistakeAttachmentStore.save(
            data: original,
            preferredExtension: "png",
            directory: directory
        )
        _ = try MistakeAttachmentStore.stageForDeletion(
            fileNames: [referencedName, deletedName],
            directory: directory
        )
        try MistakeAttachmentStore.recoverInterruptedDeletions(
            referencedFileNames: [referencedName],
            directory: directory
        )
        expect(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent(referencedName).path),
            "startup recovery restores a file still referenced by the database"
        )
        expect(
            !FileManager.default.fileExists(atPath: directory.appendingPathComponent(deletedName).path),
            "startup recovery commits a file no longer referenced by the database"
        )
        expect(
            !FileManager.default.fileExists(
                atPath: directory.appendingPathComponent(".DeletionStaging").path
            ),
            "startup recovery removes an empty staging directory"
        )

        print("MistakeAttachmentStoreTests: 12 passed")
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
