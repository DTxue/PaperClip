import Foundation
import SwiftData

struct VocabularyCardRowData: Identifiable, Equatable {
    let id: UUID
    let term: String
    let definition: String
    let phonetic: String
    let example: String

    init(card: VocabularyCard) {
        self.id = card.id
        self.term = card.term
        self.definition = card.definition
        self.phonetic = card.phonetic
        self.example = card.example
    }

    init(
        id: UUID,
        term: String,
        definition: String,
        phonetic: String = "",
        example: String = ""
    ) {
        self.id = id
        self.term = term
        self.definition = definition
        self.phonetic = phonetic
        self.example = example
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyCard>] {
        [
            \.id,
            \.term,
            \.definition,
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
