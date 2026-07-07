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
