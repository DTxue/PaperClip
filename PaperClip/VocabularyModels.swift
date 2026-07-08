import Foundation
import SwiftData

@Model
final class VocabularyFolder {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyFolder>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class VocabularyDeck {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var folderID: UUID?
    var title: String
    var sourceLanguage: String
    var targetLanguage: String
    var dailyNewLimit: Int
    var desiredRetention: Double
    var fsrsParametersJSON: String = ""
    var schedulerVersion: Int = 6
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        folderID: UUID? = nil,
        title: String,
        sourceLanguage: String = "英语",
        targetLanguage: String = "中文",
        dailyNewLimit: Int = 20,
        desiredRetention: Double = 0.9,
        fsrsParametersJSON: String = "",
        schedulerVersion: Int = 6,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.folderID = folderID
        self.title = title
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.dailyNewLimit = dailyNewLimit
        self.desiredRetention = desiredRetention
        self.fsrsParametersJSON = fsrsParametersJSON
        self.schedulerVersion = schedulerVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class VocabularyCard {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var term: String
    var definition: String
    var englishDefinition: String = ""
    var phonetic: String
    var example: String
    var partOfSpeech: String
    var tagsText: String
    var note: String
    var alternativeAnswersText: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        deckID: UUID,
        term: String,
        definition: String,
        englishDefinition: String = "",
        phonetic: String = "",
        example: String = "",
        partOfSpeech: String = "",
        tagsText: String = "",
        note: String = "",
        alternativeAnswersText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.deckID = deckID
        self.term = term
        self.definition = definition
        self.englishDefinition = englishDefinition
        self.phonetic = phonetic
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.tagsText = tagsText
        self.note = note
        self.alternativeAnswersText = alternativeAnswersText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

}

@Model
final class VocabularyGeneratedArticle {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyGeneratedArticle>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var title: String
    var articleText: String
    var coveredTermsJSON: String
    var sourceCardSnapshotHash: String
    var modelName: String
    var promptVersion: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        deckID: UUID,
        title: String,
        articleText: String,
        coveredTermsJSON: String = "[]",
        sourceCardSnapshotHash: String,
        modelName: String,
        promptVersion: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.deckID = deckID
        self.title = title
        self.articleText = articleText
        self.coveredTermsJSON = coveredTermsJSON
        self.sourceCardSnapshotHash = sourceCardSnapshotHash
        self.modelName = modelName
        self.promptVersion = promptVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class VocabularyArticleRecitationHistory {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyArticleRecitationHistory>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var articleID: UUID
    var articleTitle: String
    var articleSnapshotHash: String
    var completedAt: Date
    var duration: TimeInterval
    var sentenceCount: Int
    var wordCount: Int
    var stuckSentenceIndexesJSON: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        deckID: UUID,
        articleID: UUID,
        articleTitle: String,
        articleSnapshotHash: String,
        completedAt: Date = .now,
        duration: TimeInterval,
        sentenceCount: Int,
        wordCount: Int,
        stuckSentenceIndexes: [Int] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.deckID = deckID
        self.articleID = articleID
        self.articleTitle = articleTitle
        self.articleSnapshotHash = articleSnapshotHash
        self.completedAt = completedAt
        self.duration = duration
        self.sentenceCount = sentenceCount
        self.wordCount = wordCount
        self.stuckSentenceIndexesJSON = Self.encodeStuckSentenceIndexes(stuckSentenceIndexes)
        self.createdAt = createdAt
    }

    var stuckSentenceIndexes: [Int] {
        get {
            guard let data = stuckSentenceIndexesJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set {
            stuckSentenceIndexesJSON = Self.encodeStuckSentenceIndexes(newValue)
        }
    }

    private static func encodeStuckSentenceIndexes(_ indexes: [Int]) -> String {
        let uniqueIndexes = Array(Set(indexes)).sorted()
        guard let data = try? JSONEncoder().encode(uniqueIndexes),
              let json = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return json
    }
}
