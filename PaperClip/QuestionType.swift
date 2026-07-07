import Foundation

enum QuestionType: String, CaseIterable, Identifiable {
    case choice = "选择题"
    case fillBlank = "填空题"
    case trueFalse = "判断题"
    case calculation = "计算题"
    case reading = "阅读理解"
    case shortAnswer = "简答题"
    case proof = "证明题"
    case composition = "作文题"
    case other = "其他"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .choice: "list.bullet.circle"
        case .fillBlank: "rectangle.and.pencil.and.ellipsis"
        case .trueFalse: "checkmark.circle"
        case .calculation: "function"
        case .reading: "text.book.closed"
        case .shortAnswer: "text.alignleft"
        case .proof: "checkmark.seal"
        case .composition: "doc.richtext"
        case .other: "square.grid.2x2"
        }
    }

    static func resolve(_ value: String, questionText: String = "") -> QuestionType {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = allCases.first(where: { $0.rawValue == trimmed }) {
            return exact
        }

        let normalized = trimmed.lowercased()
        if let matched = resolveFromTypeText(normalized) {
            return matched
        }

        let text = questionText.lowercased()
        if hasChoiceMarkers(in: text) { return .choice }
        if text.contains("判断下列") || text.contains("判断正误") || text.contains("正确还是错误") {
            return .trueFalse
        }
        if text.contains("填空") || text.contains("横线上") || text.contains("空格中") {
            return .fillBlank
        }
        if text.contains("阅读材料") || text.contains("阅读下面") || text.contains("阅读短文") {
            return .reading
        }
        if text.contains("计算") || text.contains("求值") || text.contains("解方程") {
            return .calculation
        }
        if text.contains("证明") { return .proof }
        if text.contains("作文") || text.contains("写作") { return .composition }

        return .other
    }

    private static func resolveFromTypeText(_ text: String) -> QuestionType? {
        if text.contains("选择") || text.contains("单选") || text.contains("多选") {
            return .choice
        }
        if text.contains("填空") { return .fillBlank }
        if text.contains("判断") || text.contains("是非") { return .trueFalse }
        if text.contains("计算") || text.contains("运算") || text.contains("解方程") {
            return .calculation
        }
        if text.contains("阅读") || text.contains("材料分析") { return .reading }
        if text.contains("简答") || text.contains("问答") { return .shortAnswer }
        if text.contains("证明") { return .proof }
        if text.contains("作文") || text.contains("写作") { return .composition }
        return nil
    }

    private static func hasChoiceMarkers(in text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return choiceMarkerExpression.numberOfMatches(in: text, range: range) >= 2
    }

    private static let choiceMarkerExpression = try! NSRegularExpression(
        pattern: #"(?:^|[\s\n])[（(]?[A-Da-dＡ-Ｄａ-ｄ][）)]?\s*[\.．、:：]"#
    )
}
