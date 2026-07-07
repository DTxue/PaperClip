import Foundation

extension AIWritingReviewResult {
    struct LanguageUpgrade: Codable, Identifiable, Sendable {
        var id: String { originalExpression + betterSentence }
        let originalExpression: String
        let problem: String
        let betterWords: [String]
        let betterSentence: String
        let whyBetter: String

        private enum CodingKeys: String, CodingKey {
            case originalExpression, problem, betterWords, betterSentence, whyBetter
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            originalExpression = container.decodeString(.originalExpression)
            problem = container.decodeString(.problem)
            betterWords = container.decodeStringArray(.betterWords)
            betterSentence = container.decodeString(.betterSentence)
            whyBetter = container.decodeString(.whyBetter)
        }

        var betterWordsText: String {
            AIWritingReviewDisplayText.chineseList(betterWords)
        }
    }

    struct ParagraphAdvice: Codable, Identifiable, Sendable {
        var id: String { paragraph + comment }
        let paragraph: String
        let comment: String
        let revisionAdvice: String

        private enum CodingKeys: String, CodingKey {
            case paragraph, comment, revisionAdvice
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            paragraph = container.decodeString(.paragraph)
            comment = container.decodeString(.comment)
            revisionAdvice = container.decodeString(.revisionAdvice)
        }
    }

    struct SampleUpgrade: Codable, Sendable {
        let originalProblem: String
        let improvedExample: String
        let whyBetter: String

        private enum CodingKeys: String, CodingKey {
            case originalProblem, improvedExample, whyBetter
        }

        init(originalProblem: String = "", improvedExample: String = "", whyBetter: String = "") {
            self.originalProblem = originalProblem
            self.improvedExample = improvedExample
            self.whyBetter = whyBetter
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            originalProblem = container.decodeString(.originalProblem)
            improvedExample = container.decodeString(.improvedExample)
            whyBetter = container.decodeString(.whyBetter)
        }
    }
}
