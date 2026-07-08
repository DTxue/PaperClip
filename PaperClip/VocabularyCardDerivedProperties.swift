import Foundation
import SwiftData

extension VocabularyCard {
    var alternativeAnswers: [String] {
        alternativeAnswersText
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static var homeCountPropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [\.id, \.deckID]
    }

    static var sessionPropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.id,
            \.deckID,
            \.term,
            \.definition,
            \.englishDefinition,
            \.phonetic,
            \.example,
            \.alternativeAnswersText,
            \.createdAt
        ]
    }

    static var deckSettingsPropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.id,
            \.term,
            \.definition,
            \.englishDefinition,
            \.partOfSpeech,
            \.example,
            \.createdAt
        ]
    }

    static var articleGenerationPropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.id,
            \.term,
            \.definition,
            \.englishDefinition,
            \.phonetic,
            \.example,
            \.partOfSpeech,
            \.tagsText,
            \.note,
            \.alternativeAnswersText,
            \.createdAt
        ]
    }

    static var importMergePropertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.term,
            \.englishDefinition,
            \.phonetic,
            \.example,
            \.partOfSpeech,
            \.tagsText,
            \.note,
            \.alternativeAnswersText
        ]
    }
}
