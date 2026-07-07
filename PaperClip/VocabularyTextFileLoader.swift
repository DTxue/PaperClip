import Foundation

struct VocabularyImportedTextFile {
    let text: String
    let fileName: String
    let defaultTitle: String
    let isCSV: Bool
}

enum VocabularyTextFileLoader {
    static func load(from url: URL) async throws -> VocabularyImportedTextFile {
        try await Task.detached(priority: .userInitiated) {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            guard let decoded = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .utf16)
                    ?? String(data: data, encoding: .unicode) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }

            let fileTitle = url.deletingPathExtension().lastPathComponent
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackTitle = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
            let defaultTitle = fileTitle.isEmpty ? fallbackTitle : fileTitle

            return VocabularyImportedTextFile(
                text: decoded,
                fileName: url.lastPathComponent,
                defaultTitle: defaultTitle,
                isCSV: url.pathExtension.lowercased() == "csv"
            )
        }.value
    }
}
