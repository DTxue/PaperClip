import Foundation
import SwiftData

enum WritingReviewStatus: String, Codable {
    case draft
    case recognizing
    case recognized
    case grading
    case graded
    case failed

    var title: String {
        switch self {
        case .draft: "草稿"
        case .recognizing: "识别中"
        case .recognized: "已识别"
        case .grading: "批阅中"
        case .graded: "已批阅"
        case .failed: "失败"
        }
    }
}

extension PaperClipSchemaV1 {
@Model
final class WritingReview {
    static var deletionPropertiesToFetch: [PartialKeyPath<WritingReview>] {
        [\.id]
    }

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
        language: WritingLanguage,
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
        self.languageRaw = language.rawValue
        self.recognizedText = recognizedText
        self.reviewJSONData = reviewJSONData
        self.overallJudgement = overallJudgement
        self.teacherComment = teacherComment
        self.scoreText = scoreText
        self.createdAt = createdAt
    }

    var language: WritingLanguage {
        WritingLanguage(rawValue: languageRaw) ?? .chinese
    }
}
}

typealias WritingReview = PaperClipSchemaV1.WritingReview
