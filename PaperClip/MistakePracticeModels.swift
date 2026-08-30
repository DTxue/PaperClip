import Foundation
import SwiftData

extension PaperClipSchemaV1 {
/// Legacy persisted model retained only so existing stores and backups remain readable.
@Model
final class MistakePracticeLayer {
    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var practiceGroupID: UUID
    /// 第几轮（从 1 开始），"再练一轮"时递增
    var round: Int
    @Attribute(.externalStorage) var drawingData: Data
    /// "" 未标记 | "got_it" 会了 | "not_yet" 还不会
    var mark: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cardID: UUID,
        practiceGroupID: UUID,
        round: Int = 1,
        drawingData: Data = Data(),
        mark: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.cardID = cardID
        self.practiceGroupID = practiceGroupID
        self.round = round
        self.drawingData = drawingData
        self.mark = mark
        self.createdAt = createdAt
    }
}
}

typealias MistakePracticeLayer = PaperClipSchemaV1.MistakePracticeLayer
