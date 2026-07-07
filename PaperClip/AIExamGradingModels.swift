import Foundation

struct AIExamGradingResult: Decodable, Sendable {
    let items: [AIExamGradingItem]
}

struct AIExamGradingItem: Decodable, Sendable {
    struct Anchor: Decodable, Sendable {
        let x: Double
        let y: Double

        private enum CodingKeys: String, CodingKey {
            case x, y
        }

        init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            x = container.decodeFlexibleDouble(.x)
            y = container.decodeFlexibleDouble(.y)
        }
    }

    let pageIndex: Int
    let questionNumber: String
    let isCorrect: Bool
    let stampAnchor: Anchor
    let confidence: Double

    private enum CodingKeys: String, CodingKey {
        case pageIndex, questionNumber, isCorrect, stampAnchor, confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageIndex = container.decodeFlexibleInt(.pageIndex)
        questionNumber = container.decodeString(.questionNumber)
        isCorrect = (try? container.decode(Bool.self, forKey: .isCorrect)) ?? false
        stampAnchor = (try? container.decode(Anchor.self, forKey: .stampAnchor))
            ?? Anchor(x: 0.86, y: 0.18)
        confidence = container.decodeFlexibleDouble(.confidence)
    }
}
