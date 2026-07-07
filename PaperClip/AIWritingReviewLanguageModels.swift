import Foundation

extension AIWritingReviewResult {
    struct GoodWordsAndSentences: Codable, Sendable {
        let words: [Word]
        let phrases: [Phrase]
        let sentences: [Sentence]
        let sentencePatterns: [SentencePattern]
        let openingSentences: [String]
        let transitionSentences: [String]
        let endingSentences: [String]
        let stackingAdvice: String

        private enum CodingKeys: String, CodingKey {
            case words, phrases, sentences, sentencePatterns
            case openingSentences, transitionSentences, endingSentences, stackingAdvice
        }

        init(
            words: [Word] = [],
            phrases: [Phrase] = [],
            sentences: [Sentence] = [],
            sentencePatterns: [SentencePattern] = [],
            openingSentences: [String] = [],
            transitionSentences: [String] = [],
            endingSentences: [String] = [],
            stackingAdvice: String = ""
        ) {
            self.words = words
            self.phrases = phrases
            self.sentences = sentences
            self.sentencePatterns = sentencePatterns
            self.openingSentences = openingSentences
            self.transitionSentences = transitionSentences
            self.endingSentences = endingSentences
            self.stackingAdvice = stackingAdvice
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            words = container.decodeArray([Word].self, .words)
            phrases = container.decodeArray([Phrase].self, .phrases)
            sentences = container.decodeArray([Sentence].self, .sentences)
            sentencePatterns = container.decodeArray([SentencePattern].self, .sentencePatterns)
            openingSentences = container.decodeStringArray(.openingSentences)
            transitionSentences = container.decodeStringArray(.transitionSentences)
            endingSentences = container.decodeStringArray(.endingSentences)
            stackingAdvice = container.decodeString(.stackingAdvice)
        }
    }
}
