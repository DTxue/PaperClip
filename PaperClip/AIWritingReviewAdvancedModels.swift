import Foundation

extension AIWritingReviewResult {
    struct TopicTaskAnalysis: Codable, Sendable {
        let keywords: [String]
        let realTask: String
        let studentHandling: String
        let riskOfShallowWriting: String
        let bestWritingDirection: String

        private enum CodingKeys: String, CodingKey {
            case keywords, realTask, studentHandling, riskOfShallowWriting, bestWritingDirection
        }

        init() {
            keywords = []
            realTask = ""
            studentHandling = ""
            riskOfShallowWriting = ""
            bestWritingDirection = ""
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            keywords = container.decodeStringArray(.keywords)
            realTask = container.decodeString(.realTask)
            studentHandling = container.decodeString(.studentHandling)
            riskOfShallowWriting = container.decodeString(.riskOfShallowWriting)
            bestWritingDirection = container.decodeString(.bestWritingDirection)
        }

        var keywordsText: String {
            AIWritingReviewDisplayText.chineseList(keywords)
        }
    }

    struct WritingAbilityDiagnosis: Codable, Identifiable, Sendable {
        var id: String { ability + evidenceFromEssay }
        let ability: String
        let evidenceFromEssay: String
        let impact: String
        let trainingSuggestion: String

        private enum CodingKeys: String, CodingKey {
            case ability, evidenceFromEssay, impact, trainingSuggestion
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            ability = container.decodeString(.ability)
            evidenceFromEssay = container.decodeString(.evidenceFromEssay)
            impact = container.decodeString(.impact)
            trainingSuggestion = container.decodeString(.trainingSuggestion)
        }
    }

}
