import Foundation

struct VocabularyArticleCardInput: Encodable, Hashable {
    let term: String
    let definition: String
    let phonetic: String
    let example: String
    let partOfSpeech: String
    let tagsText: String
    let note: String
    let alternativeAnswersText: String

    init(
        term: String,
        definition: String,
        phonetic: String = "",
        example: String = "",
        partOfSpeech: String = "",
        tagsText: String = "",
        note: String = "",
        alternativeAnswersText: String = ""
    ) {
        self.term = term
        self.definition = definition
        self.phonetic = phonetic
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.tagsText = tagsText
        self.note = note
        self.alternativeAnswersText = alternativeAnswersText
    }
}

struct VocabularyArticleDraft {
    let title: String
    let articleText: String
    let coveredTerms: [String]
    let sourceCardSnapshotHash: String
    let modelName: String
    let promptVersion: Int
}

struct VocabularyArticleGenerationResult: Decodable {
    let title: String
    let article: String
    let coveredTerms: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case article
        case coveredTerms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Vocabulary Story"
        article = try container.decode(String.self, forKey: .article)
        coveredTerms = try container.decodeIfPresent([String].self, forKey: .coveredTerms) ?? []
    }
}

struct VocabularyArticleSentence: Identifiable, Equatable {
    let id: Int
    let text: String
    let words: [String]

    static func split(_ articleText: String) -> [VocabularyArticleSentence] {
        var sentences: [String] = []
        var current = ""

        for character in articleText {
            current.append(character)
            if ".!?".contains(character) {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                current = ""
            }
        }

        let remainder = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainder.isEmpty {
            sentences.append(remainder)
        }

        return sentences.enumerated().map { index, sentence in
            VocabularyArticleSentence(
                id: index,
                text: sentence,
                words: VocabularyArticleTextNormalizer.words(from: sentence)
            )
        }.filter { !$0.words.isEmpty }
    }
}

enum VocabularyArticleTextNormalizer {
    static func words(from text: String) -> [String] {
        var normalized = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "i'm", with: "i am")
            .replacingOccurrences(of: "you're", with: "you are")
            .replacingOccurrences(of: "we're", with: "we are")
            .replacingOccurrences(of: "they're", with: "they are")
            .replacingOccurrences(of: "it's", with: "it is")
            .replacingOccurrences(of: "that's", with: "that is")
            .replacingOccurrences(of: "there's", with: "there is")
            .replacingOccurrences(of: "can't", with: "cannot")
            .replacingOccurrences(of: "won't", with: "will not")
            .replacingOccurrences(of: "don't", with: "do not")
            .replacingOccurrences(of: "doesn't", with: "does not")
            .replacingOccurrences(of: "didn't", with: "did not")
            .replacingOccurrences(of: "isn't", with: "is not")
            .replacingOccurrences(of: "aren't", with: "are not")
            .replacingOccurrences(of: "wasn't", with: "was not")
            .replacingOccurrences(of: "weren't", with: "were not")
            .replacingOccurrences(of: "haven't", with: "have not")
            .replacingOccurrences(of: "hasn't", with: "has not")
            .replacingOccurrences(of: "hadn't", with: "had not")
            .replacingOccurrences(of: "wouldn't", with: "would not")
            .replacingOccurrences(of: "shouldn't", with: "should not")
            .replacingOccurrences(of: "couldn't", with: "could not")

        normalized = normalized
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")

        return normalized
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

struct VocabularyArticleRecitationState: Equatable {
    private(set) var sentences: [VocabularyArticleSentence]
    private(set) var currentSentenceIndex: Int = 0
    private(set) var currentWordIndex: Int = 0
    private(set) var lastMismatchWord: String?

    init(sentences: [VocabularyArticleSentence]) {
        self.sentences = sentences
    }

    var revealedSentenceCount: Int {
        currentSentenceIndex
    }

    var isComplete: Bool {
        currentSentenceIndex >= sentences.count && !sentences.isEmpty
    }

    var currentSentence: VocabularyArticleSentence? {
        guard sentences.indices.contains(currentSentenceIndex) else { return nil }
        return sentences[currentSentenceIndex]
    }

    var currentProgressText: String {
        guard let currentSentence else { return "" }
        return "\(min(currentWordIndex, currentSentence.words.count))/\(currentSentence.words.count)"
    }

    mutating func reset() {
        currentSentenceIndex = 0
        currentWordIndex = 0
        lastMismatchWord = nil
    }

    mutating func process(words incomingWords: [String]) {
        for word in incomingWords {
            process(word)
        }
    }

    mutating func process(_ rawWord: String) {
        guard let currentSentence else { return }
        let targetWords = currentSentence.words
        guard targetWords.indices.contains(currentWordIndex) else { return }

        if rawWord == targetWords[currentWordIndex] {
            currentWordIndex += 1
            lastMismatchWord = nil
            if currentWordIndex == targetWords.count {
                currentSentenceIndex += 1
                currentWordIndex = 0
            }
            return
        }

        if currentWordIndex > 0 && targetWords[..<currentWordIndex].contains(rawWord) {
            return
        }

        lastMismatchWord = rawWord
        currentWordIndex = 0
    }
}

enum VocabularyArticleSourceFingerprint {
    static func make(cards: [VocabularyArticleCardInput]) -> String {
        let payload = cards.map {
            [
                $0.term,
                $0.definition,
                $0.phonetic,
                $0.example,
                $0.partOfSpeech,
                $0.tagsText,
                $0.note,
                $0.alternativeAnswersText
            ].joined(separator: "\u{1F}")
        }.joined(separator: "\u{1E}")

        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in payload.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
