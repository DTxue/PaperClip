import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class ExamGradeMark {
    @Attribute(.unique) var id: UUID
    var sourceDocumentId: UUID
    var attemptId: UUID
    var pageIndex: Int
    var isCorrect: Bool
    /// 归一化位置，格式 "x,y"，以考试 PDF 当前页左上角为原点。
    var normalizedAnchor: String
    var confidence: Double
    var questionNumber: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sourceDocumentId: UUID,
        attemptId: UUID,
        pageIndex: Int,
        isCorrect: Bool,
        normalizedAnchor: String,
        confidence: Double = 0,
        questionNumber: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sourceDocumentId = sourceDocumentId
        self.attemptId = attemptId
        self.pageIndex = pageIndex
        self.isCorrect = isCorrect
        self.normalizedAnchor = normalizedAnchor
        self.confidence = confidence
        self.questionNumber = questionNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
}

typealias ExamGradeMark = PaperClipSchemaV1.ExamGradeMark

extension ExamGradeMark {
    static var deletionPropertiesToFetch: [PartialKeyPath<ExamGradeMark>] {
        [\.id]
    }

    static var workspacePropertiesToFetch: [PartialKeyPath<ExamGradeMark>] {
        [
            \.id,
            \.attemptId,
            \.pageIndex,
            \.isCorrect,
            \.normalizedAnchor,
            \.confidence
        ]
    }
}
