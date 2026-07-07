import Foundation

extension AIWritingReviewResult {
    struct Problem: Codable, Identifiable, Sendable {
        var id: String { problem + evidenceFromEssay }
        let problem: String
        let evidenceFromEssay: String
        let whyItWeakensEssay: String
        let howToImprove: String

        private enum CodingKeys: String, CodingKey {
            case problem, evidenceFromEssay, whyItWeakensEssay, howToImprove
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            problem = container.decodeString(.problem)
            evidenceFromEssay = container.decodeString(.evidenceFromEssay)
            whyItWeakensEssay = container.decodeString(.whyItWeakensEssay)
            howToImprove = container.decodeString(.howToImprove)
        }
    }

    struct IdeaUpgrade: Codable, Sendable {
        let currentIdea: String
        let betterDirection: String
        let suggestedThemeSentence: String

        private enum CodingKeys: String, CodingKey {
            case currentIdea, betterDirection, suggestedThemeSentence
        }

        init(currentIdea: String = "", betterDirection: String = "", suggestedThemeSentence: String = "") {
            self.currentIdea = currentIdea
            self.betterDirection = betterDirection
            self.suggestedThemeSentence = suggestedThemeSentence
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentIdea = container.decodeString(.currentIdea)
            betterDirection = container.decodeString(.betterDirection)
            suggestedThemeSentence = container.decodeString(.suggestedThemeSentence)
        }
    }

    struct ContentAdvice: Codable, Identifiable, Sendable {
        var id: String { sourceContent + keepOrChange }
        let sourceContent: String
        let keepOrChange: String
        let reason: String
        let revisionAdvice: String

        private enum CodingKeys: String, CodingKey {
            case sourceContent, keepOrChange, reason, revisionAdvice
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sourceContent = container.decodeString(.sourceContent)
            keepOrChange = container.decodeString(.keepOrChange)
            reason = container.decodeString(.reason)
            revisionAdvice = container.decodeString(.revisionAdvice)
        }
    }

    struct StructureAdvice: Codable, Identifiable, Sendable {
        var id: String { part + problem }
        let part: String
        let problem: String
        let revisionAdvice: String

        private enum CodingKeys: String, CodingKey {
            case part, problem, revisionAdvice
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            part = container.decodeString(.part)
            problem = container.decodeString(.problem)
            revisionAdvice = container.decodeString(.revisionAdvice)
        }
    }
}
