import Foundation
import SwiftData

extension PaperClipSchemaV1 {
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

typealias ExamHandwritingLayer = PaperClipSchemaV1.ExamHandwritingLayer

extension ExamHandwritingLayer {
    static var deletionPropertiesToFetch: [PartialKeyPath<ExamHandwritingLayer>] {
        [\.id]
    }

    static var workspacePropertiesToFetch: [PartialKeyPath<ExamHandwritingLayer>] {
        [\.id, \.pageIndex, \.drawingData, \.updatedAt]
    }
}
