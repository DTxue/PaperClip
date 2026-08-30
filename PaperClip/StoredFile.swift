import Foundation

enum StoredFile: Hashable {
    case importedPDF(fileName: String)
    case examPDF(fileName: String)
    case mistakeAttachment(fileName: String)

    var url: URL {
        switch self {
        case .importedPDF(let fileName):
            AppStorageDirectory.pdfs.appendingPathComponent(fileName)
        case .examPDF(let fileName):
            AppStorageDirectory.examPDFs.appendingPathComponent(fileName)
        case .mistakeAttachment(let fileName):
            AppStorageDirectory.mistakeAttachments.appendingPathComponent(fileName)
        }
    }
}
