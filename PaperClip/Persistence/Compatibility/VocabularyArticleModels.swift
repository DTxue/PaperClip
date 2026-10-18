import Foundation
import SwiftData

extension PaperClipSchemaV1 {
/// V1–V3 迁移专用；V4 已移除该实体。
@Model
final class VocabularyGeneratedArticle {
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

/// V1–V3 迁移专用；V4 已移除该实体。
@Model
final class VocabularyArticleRecitationHistory {
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
}
