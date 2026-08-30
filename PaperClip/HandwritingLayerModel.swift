import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class HandwritingLayer {
    static var deletionPropertiesToFetch: [PartialKeyPath<HandwritingLayer>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var documentId: UUID
    var pageIndex: Int
    @Attribute(.externalStorage) var drawingData: Data
    /// 同一次做题会话内所有页面共享同一个 sessionIndex（从 1 开始）。
    /// 旧数据迁移后默认为 1，"新建练习"时递增。
    var sessionIndex: Int = 1
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        documentId: UUID,
        pageIndex: Int,
        drawingData: Data,
        sessionIndex: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.documentId = documentId
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.sessionIndex = sessionIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
}

typealias HandwritingLayer = PaperClipSchemaV1.HandwritingLayer
