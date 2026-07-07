import Foundation

enum VocabularyDirection: String, CaseIterable, Identifiable {
    case termToDefinition
    case definitionToTerm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termToDefinition: "单词 → 释义"
        case .definitionToTerm: "释义 → 单词"
        }
    }
}

enum VocabularyMemoryStage: String {
    case new
    case learning
    case review
    case relearning
}
