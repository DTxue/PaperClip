import Foundation

extension AIWritingReviewResult.GoodWordsAndSentences {
    struct Word: Codable, Identifiable, Sendable {
        var id: String { word + example }
        let word: String
        let meaning: String
        let whereToUse: String
        let example: String

        private enum CodingKeys: String, CodingKey {
            case word, meaning, whereToUse, example
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            word = container.decodeString(.word)
            meaning = container.decodeString(.meaning)
            whereToUse = container.decodeString(.whereToUse)
            example = container.decodeString(.example)
        }
    }

    struct Phrase: Codable, Identifiable, Sendable {
        var id: String { phrase + example }
        let phrase: String
        let whereToUse: String
        let example: String

        private enum CodingKeys: String, CodingKey {
            case phrase, whereToUse, example
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            phrase = container.decodeString(.phrase)
            whereToUse = container.decodeString(.whereToUse)
            example = container.decodeString(.example)
        }
    }

    struct Sentence: Codable, Identifiable, Sendable {
        var id: String { sentence + whereToUse }
        let sentence: String
        let whereToUse: String
        let whyUseful: String

        private enum CodingKeys: String, CodingKey {
            case sentence, whereToUse, whyUseful
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sentence = container.decodeString(.sentence)
            whereToUse = container.decodeString(.whereToUse)
            whyUseful = container.decodeString(.whyUseful)
        }
    }

    struct SentencePattern: Codable, Identifiable, Sendable {
        var id: String { pattern + example }
        let pattern: String
        let usage: String
        let example: String

        private enum CodingKeys: String, CodingKey {
            case pattern, usage, example
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            pattern = container.decodeString(.pattern)
            usage = container.decodeString(.usage)
            example = container.decodeString(.example)
        }
    }
}
