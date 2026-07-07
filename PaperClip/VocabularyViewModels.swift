import Foundation
import SwiftData

struct VocabularyDeckRowData: Identifiable, Equatable {
    let id: UUID
    let title: String
    let updatedAt: Date

    init(deck: VocabularyDeck) {
        self.id = deck.id
        self.title = deck.title
        self.updatedAt = deck.updatedAt
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.title, \.updatedAt]
    }
}
