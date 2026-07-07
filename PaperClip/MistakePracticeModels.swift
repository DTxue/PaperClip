import Foundation
import SwiftData

/// 一次错题练习会话中，每张错题卡对应一个画布层 + 标记结果。
/// practiceGroupID 将同一批次的多轮练习关联在一起（"再练一轮"时 round 递增）。
@Model
final class MistakePracticeLayer {
    static var roundCountPropertiesToFetch: [PartialKeyPath<MistakePracticeLayer>] {
        [\.cardID, \.practiceGroupID, \.round]
    }

    static var deletionPropertiesToFetch: [PartialKeyPath<MistakePracticeLayer>] {
        [\.id]
    }

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

enum PracticeMark: String {
    case gotIt    = "got_it"
    case notYet   = "not_yet"
    case unmarked = ""
}

struct MistakePracticeRoundCountInput {
    let cardID: UUID
    let practiceGroupID: UUID
    let round: Int

    init(cardID: UUID, practiceGroupID: UUID, round: Int) {
        self.cardID = cardID
        self.practiceGroupID = practiceGroupID
        self.round = round
    }
}

enum MistakePracticeRoundCounter {
    private struct RoundKey: Hashable {
        let groupID: UUID
        let round: Int
    }

    static func countByCardID(_ inputs: [MistakePracticeRoundCountInput]) -> [UUID: Int] {
        countByCardID(inputs) { input in
            (input.cardID, input.practiceGroupID, input.round)
        }
    }

    static func countByCardID<LayerSequence: Sequence>(
        _ layers: LayerSequence,
        layerFields: (LayerSequence.Element) -> (cardID: UUID, practiceGroupID: UUID, round: Int)
    ) -> [UUID: Int] {
        var roundsByCardID: [UUID: Set<RoundKey>] = [:]
        for layer in layers {
            let fields = layerFields(layer)
            roundsByCardID[fields.cardID, default: []].insert(
                RoundKey(groupID: fields.practiceGroupID, round: fields.round)
            )
        }
        return roundsByCardID.mapValues(\.count)
    }
}
