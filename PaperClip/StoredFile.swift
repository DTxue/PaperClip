import Foundation

enum StoredFile: Hashable {
    case mistakeAttachment(fileName: String)

    var url: URL {
        switch self {
        case .mistakeAttachment(let fileName):
            AppStorageDirectory.mistakeAttachments.appendingPathComponent(fileName)
        }
    }
}
