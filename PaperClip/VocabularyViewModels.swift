import Foundation
import SwiftData

struct VocabularyFolderRowData: Identifiable, Equatable {
    let id: UUID
    let title: String
    let updatedAt: Date

    init(folder: VocabularyFolder) {
        self.id = folder.id
        self.title = folder.title
        self.updatedAt = folder.updatedAt
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyFolder>] {
        [\.id, \.title, \.updatedAt]
    }
}

struct VocabularyDeckRowData: Identifiable, Equatable {
    let id: UUID
    let folderID: UUID?
    let title: String
    let updatedAt: Date

    init(deck: VocabularyDeck) {
        self.id = deck.id
        self.folderID = deck.folderID
        self.title = deck.title
        self.updatedAt = deck.updatedAt
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.folderID, \.title, \.updatedAt]
    }
}
