import Foundation
import SwiftData

/// Historical V1–V4 migration model. Writing is not part of the current schema.
extension PaperClipSchemaV1 {
@Model
final class WritingReview {
    @Attribute(.unique) var id: UUID
    var promptID: UUID
    var draftID: UUID
    var languageRaw: String
    var recognizedText: String
    @Attribute(.externalStorage) var reviewJSONData: Data
    var overallJudgement: String
    var teacherComment: String
    var scoreText: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        promptID: UUID,
        draftID: UUID,
        languageRaw: String,
        recognizedText: String,
        reviewJSONData: Data,
        overallJudgement: String,
        teacherComment: String,
        scoreText: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.promptID = promptID
        self.draftID = draftID
        self.languageRaw = languageRaw
        self.recognizedText = recognizedText
        self.reviewJSONData = reviewJSONData
        self.overallJudgement = overallJudgement
        self.teacherComment = teacherComment
        self.scoreText = scoreText
        self.createdAt = createdAt
    }
}
}
