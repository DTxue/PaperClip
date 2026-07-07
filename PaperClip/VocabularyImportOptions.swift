import Foundation

enum VocabularyImportPreset: String, CaseIterable, Identifiable {
    case tab
    case pairedLines
    case csv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tab: "TXT · Tab 分隔"
        case .pairedLines: "TXT · 每两行一组"
        case .csv: "CSV · 逗号分隔"
        }
    }

    var format: VocabularyTextFormat {
        switch self {
        case .tab: .tab
        case .pairedLines: .pairedLines
        case .csv: .comma
        }
    }
}

enum VocabularyDuplicateStrategy: String, CaseIterable, Identifiable {
    case merge = "合并缺失字段"
    case skip = "跳过重复项"
    case duplicate = "作为新卡片"

    var id: String { rawValue }
}
