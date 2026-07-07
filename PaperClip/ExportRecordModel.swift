import Foundation
import SwiftData

@Model
final class ExportRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var cardIDsText: String
    var layoutType: String
    var exportType: String
    var pdfFileName: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        cardIDs: [UUID],
        layoutType: String,
        exportType: String,
        pdfFileName: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.cardIDsText = cardIDs.map(\.uuidString).joined(separator: ",")
        self.layoutType = layoutType
        self.exportType = exportType
        self.pdfFileName = pdfFileName
        self.createdAt = createdAt
    }

    var pdfURL: URL {
        StoredFile.exportPDF(fileName: pdfFileName).url
    }
}
