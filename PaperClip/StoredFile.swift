import Foundation

enum StoredFile: Hashable {
    case importedPDF(fileName: String)
    case cardImage(fileName: String)
    case examPDF(fileName: String)
    case exportPDF(fileName: String)

    var url: URL {
        switch self {
        case .importedPDF(let fileName):
            AppStorageDirectory.pdfs.appendingPathComponent(fileName)
        case .cardImage(let fileName):
            AppStorageDirectory.cards.appendingPathComponent(fileName)
        case .examPDF(let fileName):
            AppStorageDirectory.examPDFs.appendingPathComponent(fileName)
        case .exportPDF(let fileName):
            AppStorageDirectory.exports.appendingPathComponent(fileName)
        }
    }
}
