import Foundation
import SwiftData

extension PaperClipSchemaV1 {
/// 旧版数据兼容模型。试卷手写运行时功能已移除。
@Model
final class ExamHandwritingLayer {
    @Attribute(.unique) var id: UUID
    var sourceDocumentId: UUID
    var attemptId: UUID
    var pageIndex: Int
    @Attribute(.externalStorage) var drawingData: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sourceDocumentId: UUID,
        attemptId: UUID,
        pageIndex: Int,
        drawingData: Data,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sourceDocumentId = sourceDocumentId
        self.attemptId = attemptId
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
}
