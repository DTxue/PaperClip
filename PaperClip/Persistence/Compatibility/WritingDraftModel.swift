import Foundation
import SwiftData

/// Historical V1–V4 migration model. Writing is not part of the current schema.
extension PaperClipSchemaV1 {
@Model
final class WritingDraft {
    @Attribute(.unique) var id: UUID
    var promptID: UUID
    var languageRaw: String
    var paperStyleRaw: String
    var blackPaperMode: Bool
    var paperWidth: Double?
    var paperHeight: Double?
    var rulingSpacing: Double?
    @Attribute(.externalStorage) var drawingData: Data
    var recognizedText: String
    var reviewStatusRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        promptID: UUID,
        languageRaw: String,
        paperStyleRaw: String = "lined",
        blackPaperMode: Bool = false,
        paperWidth: Double = 820,
        paperHeight: Double = 1500,
        rulingSpacing: Double? = nil,
        drawingData: Data = Data(),
        recognizedText: String = "",
        reviewStatusRaw: String = "draft",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.promptID = promptID
        self.languageRaw = languageRaw
        self.paperStyleRaw = paperStyleRaw
        self.blackPaperMode = blackPaperMode
        self.paperWidth = paperWidth
        self.paperHeight = paperHeight
        self.rulingSpacing = rulingSpacing
        self.drawingData = drawingData
        self.recognizedText = recognizedText
        self.reviewStatusRaw = reviewStatusRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
}
