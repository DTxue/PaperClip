import Foundation

// 客观题和填空题使用确定性字符串比对完成本地批改。
// 主观题与没有标准答案的旧数据保留人工自评，避免未经验证的自动判分。
enum PaperAnswerGrader {
    static let choiceLabels = Set("ABCDEFGH")
    static let trueFalseCorrectValues: Set<String> = ["正确", "对", "是", "√", "true", "t"]
    static let trueFalseWrongValues: Set<String> = ["错误", "错", "否", "×", "x", "false", "f"]

    static func initialMarks(
        cards: [MistakeCard],
        selectedAnswers: [UUID: String],
        textAnswers: [UUID: String]
    ) -> [UUID: String] {
        var marks: [UUID: String] = [:]
        for card in cards where canAutomaticallyGrade(card) {
            let answer: String
            switch card.resolvedQuestionType {
            case .choice, .trueFalse:
                answer = selectedAnswers[card.id] ?? ""
            case .fillBlank:
                answer = textAnswers[card.id] ?? ""
            default:
                continue
            }
            marks[card.id] = isCorrect(answer, for: card)
                ? PracticeMark.gotIt.rawValue
                : PracticeMark.notYet.rawValue
        }
        return marks
    }

    static func canAutomaticallyGrade(_ card: MistakeCard) -> Bool {
        guard !card.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return switch card.resolvedQuestionType {
        case .choice, .trueFalse, .fillBlank: true
        default: false
        }
    }

    static func isCorrect(_ answer: String, for card: MistakeCard) -> Bool {
        switch card.resolvedQuestionType {
        case .choice:
            let normalizedAnswer = normalizedChoice(answer)
            return !normalizedAnswer.isEmpty
                && normalizedAnswer == normalizedChoice(card.correctAnswer)
        case .trueFalse:
            let normalizedAnswer = normalizedTrueFalse(answer)
            return !normalizedAnswer.isEmpty
                && normalizedAnswer == normalizedTrueFalse(card.correctAnswer)
        case .fillBlank:
            let normalizedAnswer = normalizedText(answer)
            return !normalizedAnswer.isEmpty
                && normalizedAnswer == normalizedText(card.correctAnswer)
        default:
            return false
        }
    }

    static func normalizedChoice(_ value: String) -> String {
        var text = value.uppercased()
            .replacingOccurrences(of: "Ａ", with: "A")
            .replacingOccurrences(of: "Ｂ", with: "B")
            .replacingOccurrences(of: "Ｃ", with: "C")
            .replacingOccurrences(of: "Ｄ", with: "D")
            .replacingOccurrences(of: "Ｅ", with: "E")
            .replacingOccurrences(of: "Ｆ", with: "F")
            .replacingOccurrences(of: "Ｇ", with: "G")
            .replacingOccurrences(of: "Ｈ", with: "H")
        for prefix in ["正确答案", "答案", "选项"] {
            text = text.replacingOccurrences(of: prefix, with: "")
        }
        let labels = text.filter { choiceLabels.contains($0) }
        var seen: Set<Character> = []
        return String(labels.filter { seen.insert($0).inserted })
    }

    static func normalizedTrueFalse(_ value: String) -> String {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trueFalseCorrectValues.contains(text) { return "正确" }
        if trueFalseWrongValues.contains(text) { return "错误" }
        return text
    }

    static func normalizedText(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "；", with: ";")
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "。", with: "")
            .filter { !$0.isWhitespace }
            .trimmingCharacters(in: CharacterSet(charactersIn: ";,."))
    }
}
