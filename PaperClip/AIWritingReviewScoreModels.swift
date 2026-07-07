import Foundation

extension AIWritingReviewResult {
    struct ActualLevel: Codable, Sendable {
        let level: String
        let reason: String

        private enum CodingKeys: String, CodingKey {
            case level, reason
        }

        init(level: String = "", reason: String = "") {
            self.level = level
            self.reason = reason
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            level = container.decodeString(.level)
            reason = container.decodeString(.reason)
        }
    }

    struct Score: Codable, Sendable {
        let score: Double
        let fullScore: Double
        let reason: String

        private enum CodingKeys: String, CodingKey {
            case score, fullScore, reason
        }

        init(score: Double = 0, fullScore: Double = 0, reason: String = "") {
            self.score = score
            self.fullScore = fullScore
            self.reason = reason
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            score = container.decodeFlexibleDouble(.score)
            fullScore = container.decodeFlexibleDouble(.fullScore)
            reason = container.decodeString(.reason)
        }
    }
}
