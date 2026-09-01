import Foundation
import SwiftData

extension PaperClipSchemaV1 {
/// 旧版数据兼容模型。逐页交卷运行时功能已移除。
@Model
final class ExamPageSubmission {
    @Attribute(.unique) var id: UUID
    /// SwiftData 没有复合唯一约束，用稳定 key 保证同一轮同一页只能提交一次。
    @Attribute(.unique) var submissionKey: String
    var sourceDocumentId: UUID
    var attemptId: UUID
    var pageIndex: Int
    var status: String
    var submittedAt: Date
    var gradedAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sourceDocumentId: UUID,
        attemptId: UUID,
        pageIndex: Int,
        status: String = ExamPageSubmissionStatus.submitted.rawValue,
        submittedAt: Date = .now,
        gradedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.submissionKey = Self.makeSubmissionKey(
            attemptID: attemptId,
            pageIndex: pageIndex
        )
        self.sourceDocumentId = sourceDocumentId
        self.attemptId = attemptId
        self.pageIndex = pageIndex
        self.status = status
        self.submittedAt = submittedAt
        self.gradedAt = gradedAt
        self.updatedAt = updatedAt
    }

    static func makeSubmissionKey(attemptID: UUID, pageIndex: Int) -> String {
        "\(attemptID.uuidString.lowercased()):\(pageIndex)"
    }
}
}


enum ExamPageSubmissionStatus: String {
    case submitted
    case graded
}
