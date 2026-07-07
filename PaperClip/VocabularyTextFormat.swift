enum VocabularyTextFormat: String, CaseIterable, Identifiable {
    case automatic
    case tab
    case pipe
    case equals
    case colon
    case dash
    case pairedLines
    case comma
    case json
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "自动识别"
        case .tab: "Tab 分隔"
        case .pipe: "竖线分隔"
        case .equals: "等号分隔"
        case .colon: "冒号分隔"
        case .dash: "横线分隔"
        case .pairedLines: "每两行一组"
        case .comma: "逗号分隔"
        case .json: "JSON 文本"
        case .markdown: "Markdown 表格"
        }
    }
}
