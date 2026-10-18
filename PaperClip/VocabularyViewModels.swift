import Foundation
import SwiftData

extension VocabularyDeckKind {
    var collectionName: String {
        switch self {
        case .word: "词集"
        case .sentence: "句集"
        case .dictationChinese: "语文默写集"
        case .dictationOther: "其他默写集"
        }
    }

    var listTitle: String {
        switch self {
        case .word: "单词"
        case .sentence: "短语与句子"
        case .dictationChinese: "语文"
        case .dictationOther: "其他"
        }
    }

    var itemName: String {
        switch self {
        case .word: "单词"
        case .sentence: "短语或句子"
        case .dictationChinese: "默写内容"
        case .dictationOther: "默写内容"
        }
    }

    var systemImage: String {
        switch self {
        case .word: "character.book.closed.fill"
        case .sentence: "text.quote"
        case .dictationChinese: "character.book.closed"
        case .dictationOther: "text.quote"
        }
    }

    func itemCountText(_ count: Int) -> String {
        switch self {
        case .word: "\(count) 个单词"
        case .sentence: "\(count) 条短语或句子"
        case .dictationChinese: "\(count) 条默写内容"
        case .dictationOther: "\(count) 条默写内容"
        }
    }

    func dailyNewLimitText(_ count: Int) -> String {
        switch self {
        case .word: "每日新词：\(count)"
        case .sentence: "每日新内容：\(count)"
        case .dictationChinese, .dictationOther: "每日新内容：\(count)"
        }
    }
}

extension VocabularyDirection {
    func title(for kind: VocabularyDeckKind) -> String {
        switch self {
        case .termToDefinition: "\(kind.itemName) → 释义"
        case .definitionToTerm: "释义 → \(kind.itemName)"
        }
    }
}

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
    let kind: VocabularyDeckKind
    let updatedAt: Date

    init(deck: VocabularyDeck) {
        self.id = deck.id
        self.folderID = deck.folderID
        self.title = deck.title
        self.kind = deck.kind
        self.updatedAt = deck.updatedAt
    }

    static var propertiesToFetch: [PartialKeyPath<VocabularyDeck>] {
        [\.id, \.folderID, \.title, \.sourceLanguage, \.updatedAt]
    }
}
