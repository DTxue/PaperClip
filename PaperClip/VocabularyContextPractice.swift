import Foundation

struct VocabularyContextCardInput: Equatable, Sendable {
    let cardID: UUID
    let term: String
    let definition: String
    let englishDefinition: String
    let partOfSpeech: String
    let example: String
    let alternativeAnswers: [String]
}

struct VocabularyContextGenerationResult: Codable, Sendable {
    struct Item: Codable, Sendable {
        let index: Int
        let sentence: String
        let answer: String
        let collocation: String
        let usageTip: String
    }

    let items: [Item]
}

struct VocabularyContextPracticeLesson: Codable, Equatable, Sendable {
    let items: [VocabularyContextPracticeItem]
}

struct VocabularyContextPracticeItem: Codable, Identifiable, Equatable, Sendable {
    var id: UUID { cardID }

    let cardID: UUID
    let term: String
    let definition: String
    let sentence: String
    let collocation: String
    let usageTip: String
}

enum VocabularyContextPracticeBuilder {
    static func build(
        cards: [VocabularyContextCardInput],
        generated: VocabularyContextGenerationResult,
        maximumSentenceWords: Int? = nil
    ) throws -> VocabularyContextPracticeLesson {
        let expectedIndexes = Set(cards.indices.map { $0 + 1 })
        let generatedIndexes = generated.items.map(\.index)
        guard generated.items.count == cards.count,
              Set(generatedIndexes) == expectedIndexes
        else {
            throw VocabularyContextPracticeValidationError(
                issues: ["生成结果的索引必须与 \(cards.count) 个源词条一一对应。"]
            )
        }

        let generatedByIndex = Dictionary(
            generated.items.map { ($0.index, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let contentIssues = cards.indices.flatMap { offset -> [String] in
            guard let item = generatedByIndex[offset + 1] else { return [] }
            return validationIssues(
                for: item,
                card: cards[offset],
                index: offset + 1,
                maximumSentenceWords: maximumSentenceWords
            )
        }
        guard contentIssues.isEmpty else {
            throw VocabularyContextPracticeValidationError(issues: contentIssues)
        }

        let items = try cards.enumerated().map { offset, card in
            let index = offset + 1
            guard let generatedItem = generatedByIndex[index] else {
                throw VocabularyContextPracticeValidationError(
                    issues: ["缺少第 \(index) 个词条的语境练习。"]
                )
            }

            return VocabularyContextPracticeItem(
                cardID: card.cardID,
                term: card.term,
                definition: card.definition,
                sentence: trimmed(generatedItem.sentence),
                collocation: trimmed(generatedItem.collocation),
                usageTip: trimmed(generatedItem.usageTip)
            )
        }

        return VocabularyContextPracticeLesson(items: items)
    }

    private static func validationIssues(
        for item: VocabularyContextGenerationResult.Item,
        card: VocabularyContextCardInput,
        index: Int,
        maximumSentenceWords: Int?
    ) -> [String] {
        let sentence = trimmed(item.sentence)
        let answer = trimmed(item.answer)
        var issues: [String] = []

        if sentence.isEmpty {
            issues.append("第 \(index) 题缺少完整语境句。")
        }
        if let maximumSentenceWords,
           sentence.split(whereSeparator: \.isWhitespace).count
               > max(4, maximumSentenceWords)
        {
            issues.append("第 \(index) 题的语境句超过词数上限。")
        }
        if answer.isEmpty
            || sentence.range(
                of: answer,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == nil
        {
            issues.append("第 \(index) 题的答案必须出现在完整语境句中。")
        }
        if !answer.isEmpty,
           !VocabularyContextPracticeApprovedAnswers.isAllowed(
               answer,
               for: card
           )
        {
            issues.append("第 \(index) 题的答案不是源词或词卡明确认可的答案。")
        }
        if trimmed(item.collocation).isEmpty {
            issues.append("第 \(index) 题缺少常用搭配。")
        }
        let usageTip = trimmed(item.usageTip)
        if usageTip.isEmpty
            || usageTip.range(of: #"\p{Han}"#, options: .regularExpression) == nil
        {
            issues.append("第 \(index) 题缺少中文用法提示。")
        }
        return issues
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum VocabularyContextPracticeApprovedAnswers {
    static func isAllowed(
        _ answer: String,
        for card: VocabularyContextCardInput
    ) -> Bool {
        let normalizedAnswer = normalize(answer)
        return ([card.term] + card.alternativeAnswers).contains {
            normalize($0) == normalizedAnswer
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: .current
            )
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

struct VocabularyContextPracticeCacheIdentity: Codable, Equatable, Sendable {
    let deckID: UUID
    let sourceFingerprint: String
    let gradePresetRawValue: String
    let maximumCardCount: Int
}

struct VocabularyContextPracticeCacheStore {
    private static let recordVersion = 1

    private let defaults: UserDefaults
    private let keyPrefix: String

    init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "vocabulary.contextPractice.cache"
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    func load(
        identity: VocabularyContextPracticeCacheIdentity
    ) -> VocabularyContextPracticeLesson? {
        guard let data = defaults.data(forKey: key(for: identity)),
              let record = try? JSONDecoder().decode(
                  VocabularyContextPracticeCacheRecord.self,
                  from: data
              ),
              record.version == Self.recordVersion,
              record.identity == identity,
              !record.lesson.items.isEmpty
        else { return nil }
        return record.lesson
    }

    func save(
        _ lesson: VocabularyContextPracticeLesson,
        identity: VocabularyContextPracticeCacheIdentity
    ) throws {
        guard !lesson.items.isEmpty else { return }
        let record = VocabularyContextPracticeCacheRecord(
            version: Self.recordVersion,
            identity: identity,
            lesson: lesson
        )
        defaults.set(
            try JSONEncoder().encode(record),
            forKey: key(for: identity)
        )
    }

    func remove(deckID: UUID) {
        let prefix = deckKeyPrefix(for: deckID)
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func key(for identity: VocabularyContextPracticeCacheIdentity) -> String {
        "\(deckKeyPrefix(for: identity.deckID))\(identity.gradePresetRawValue).\(identity.maximumCardCount)"
    }

    private func deckKeyPrefix(for deckID: UUID) -> String {
        "\(keyPrefix).\(deckID.uuidString.lowercased())."
    }
}

private struct VocabularyContextPracticeCacheRecord: Codable {
    let version: Int
    let identity: VocabularyContextPracticeCacheIdentity
    let lesson: VocabularyContextPracticeLesson
}

enum VocabularyContextPracticeSourceFingerprint {
    static func make(cards: [VocabularyContextCardInput]) -> String {
        let payload = cards.map { card in
            [
                card.cardID.uuidString.lowercased(),
                card.term,
                card.definition,
                card.englishDefinition,
                card.partOfSpeech,
                card.example,
                card.alternativeAnswers.joined(separator: "\u{1D}")
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

struct VocabularyContextPracticeValidationError: LocalizedError, Equatable {
    let issues: [String]

    var errorDescription: String? {
        issues.joined(separator: "；")
    }
}
