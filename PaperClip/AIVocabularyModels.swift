import Foundation

struct VocabularyCardSplitResult: Decodable, Sendable {
    struct SplitCard: Decodable, Sendable {
        let term: String
        let definition: String
    }
    let cards: [SplitCard]
}

struct VocabularyDistractorResult: Decodable, Sendable {
    let correctTiles: [String]
    let distractorTiles: [String]
}

struct DistractorConfig: Sendable {
    var totalCount: Int = 8
    var weightInflection: Int = 3
    var weightLookalike: Int = 2
    var weightSynonym: Int = 2
    var weightConfused: Int = 2
    var weightDerivation: Int = 1

    var countBreakdown: [(type: String, count: Int)] {
        let types: [(String, Int)] = [
            ("词形变体（时态/数/比较级等，如 ran/running/runs）", weightInflection),
            ("形近词（拼写相近的不同单词）", weightLookalike),
            ("近义词（同类但语义不同）", weightSynonym),
            ("常见混淆词对（如 affect/effect）", weightConfused),
            ("词性变体（同词根不同词性）", weightDerivation),
        ]
        let active = types.filter { $0.1 > 0 }
        guard !active.isEmpty else { return [] }
        let total = active.reduce(0) { $0 + $1.1 }
        var result: [(String, Int)] = []
        var assigned = 0
        for (i, item) in active.enumerated() {
            let count: Int
            if i == active.count - 1 {
                count = totalCount - assigned
            } else {
                count = max(1, Int((Double(item.1) / Double(total) * Double(totalCount)).rounded()))
            }
            assigned += count
            result.append((item.0, count))
        }
        return result
    }
}

struct VocabularyGradingItem: Codable, Sendable {
    let index: Int
    let isCorrect: Bool
    let comment: String
    let recognizedText: String

    enum CodingKeys: String, CodingKey {
        case index
        case isCorrect
        case comment
        case recognizedText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        isCorrect = try container.decode(Bool.self, forKey: .isCorrect)
        comment = container.decodeString(.comment)
        recognizedText = container.decodeString(.recognizedText)
    }
}

struct VocabularyGradingResult: Codable, Sendable {
    let items: [VocabularyGradingItem]
}
