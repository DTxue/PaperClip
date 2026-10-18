enum VocabularyTextFormat: String, CaseIterable, Identifiable {
    case tab
    case pairedLines
    case comma

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tab: "Tab 分隔"
        case .pairedLines: "每两行一组"
        case .comma: "逗号分隔"
        }
    }
}
