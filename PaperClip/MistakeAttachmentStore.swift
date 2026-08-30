import Foundation

enum MistakeAttachmentStore {
    struct StagedDeletion {
        fileprivate let stagingDirectory: URL?
        fileprivate let moves: [(original: URL, staged: URL)]

        func rollback(fileManager: FileManager = .default) throws {
            for move in moves.reversed() where fileManager.fileExists(atPath: move.staged.path) {
                try fileManager.moveItem(at: move.staged, to: move.original)
            }
            if let stagingDirectory, fileManager.fileExists(atPath: stagingDirectory.path) {
                try fileManager.removeItem(at: stagingDirectory)
            }
        }

        func commit(fileManager: FileManager = .default) throws {
            guard let stagingDirectory,
                  fileManager.fileExists(atPath: stagingDirectory.path)
            else { return }
            try fileManager.removeItem(at: stagingDirectory)
        }
    }

    static func save(
        data: Data,
        preferredExtension: String?,
        directory: URL = AppStorageDirectory.mistakeAttachments,
        fileManager: FileManager = .default
    ) throws -> String {
        let pathExtension = sanitizedExtension(preferredExtension)
        let fileName = "\(UUID().uuidString).\(pathExtension)"
        let destination = try validatedURL(for: fileName, in: directory)
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: destination, options: .atomic)
        return fileName
    }

    static func remove(
        fileName: String,
        directory: URL = AppStorageDirectory.mistakeAttachments,
        fileManager: FileManager = .default
    ) throws {
        let url = try validatedURL(for: fileName, in: directory)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    static func stageForDeletion(
        fileNames: [String],
        directory: URL = AppStorageDirectory.mistakeAttachments,
        fileManager: FileManager = .default
    ) throws -> StagedDeletion {
        let originals = try fileNames.map { try validatedURL(for: $0, in: directory) }
            .filter { fileManager.fileExists(atPath: $0.path) }
        guard !originals.isEmpty else {
            return StagedDeletion(stagingDirectory: nil, moves: [])
        }

        let stagingDirectory = directory
            .appendingPathComponent(".DeletionStaging", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        var moves: [(original: URL, staged: URL)] = []
        do {
            for original in originals {
                let staged = stagingDirectory.appendingPathComponent(original.lastPathComponent)
                try fileManager.moveItem(at: original, to: staged)
                moves.append((original, staged))
            }
            return StagedDeletion(stagingDirectory: stagingDirectory, moves: moves)
        } catch {
            try? StagedDeletion(stagingDirectory: stagingDirectory, moves: moves)
                .rollback(fileManager: fileManager)
            throw error
        }
    }

    static func recoverInterruptedDeletions(
        referencedFileNames: Set<String>,
        directory: URL = AppStorageDirectory.mistakeAttachments,
        fileManager: FileManager = .default
    ) throws {
        let stagingRoot = directory.appendingPathComponent(".DeletionStaging", isDirectory: true)
        guard fileManager.fileExists(atPath: stagingRoot.path) else { return }

        let transactionDirectories = try fileManager.contentsOfDirectory(
            at: stagingRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        for transactionDirectory in transactionDirectories {
            let stagedFiles = try fileManager.contentsOfDirectory(
                at: transactionDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            for stagedFile in stagedFiles {
                let fileName = stagedFile.lastPathComponent
                if referencedFileNames.contains(fileName) {
                    let original = try validatedURL(for: fileName, in: directory)
                    if fileManager.fileExists(atPath: original.path) {
                        try fileManager.removeItem(at: stagedFile)
                    } else {
                        try fileManager.moveItem(at: stagedFile, to: original)
                    }
                } else {
                    try fileManager.removeItem(at: stagedFile)
                }
            }
            try fileManager.removeItem(at: transactionDirectory)
        }
        try fileManager.removeItem(at: stagingRoot)
    }

    private static func validatedURL(for fileName: String, in directory: URL) throws -> URL {
        guard !fileName.isEmpty,
              fileName == URL(fileURLWithPath: fileName).lastPathComponent,
              !fileName.contains("/"),
              !fileName.contains("\\")
        else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        let root = directory.standardizedFileURL
        let candidate = root.appendingPathComponent(fileName).standardizedFileURL
        guard candidate.deletingLastPathComponent() == root else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        return candidate
    }

    private static func sanitizedExtension(_ value: String?) -> String {
        let candidate = (value ?? "")
            .lowercased()
            .filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        return candidate.isEmpty ? "jpg" : String(candidate.prefix(10))
    }
}
