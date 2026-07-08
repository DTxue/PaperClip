import Foundation
import SwiftData

struct VocabularyCardRowData: Identifiable, Equatable {
    let id: UUID
    let term: String
    let definition: String
    let englishDefinition: String
    let phonetic: String
    let example: String

    init(card: VocabularyCard) {
        self.id = card.id
        self.term = card.term
        self.definition = card.definition
        self.englishDefinition = card.englishDefinition
        self.phonetic = card.phonetic
        self.example = card.example
    }

    init(
        id: UUID,
        term: String,
        definition: String,
        englishDefinition: String = "",
        phonetic: String = "",
        example: String = ""
    ) {
        self.id = id
        self.term = term
        self.definition = definition
        self.englishDefinition = englishDefinition
        self.phonetic = phonetic
        self.example = example
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.id,
            \.term,
            \.definition,
            \.englishDefinition,
            \.phonetic,
            \.example,
            \.createdAt
        ]
    }

    func matchesSearch(_ searchText: String) -> Bool {
        searchText.isEmpty
            || term.localizedCaseInsensitiveContains(searchText)
            || definition.localizedCaseInsensitiveContains(searchText)
    }
}
