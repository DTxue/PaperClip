import Foundation

enum AppStorageDirectory {
    private static let root: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = support.appendingPathComponent("PaperClip", isDirectory: true)
        createDirectoryIfNeeded(at: url)
        return url
    }()

    static let pdfs = directory(named: "PDFs")
    static let cards = directory(named: "Cards")
    static let exports = directory(named: "Exports")
    static let examPDFs = directory(named: "ExamPDFs")
    static let examArchives = directory(named: "ExamArchives")

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
