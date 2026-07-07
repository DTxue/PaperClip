import Foundation

// Apple does not provide a system API for inferring objective-answer choices
// from OCR text. This parser only recognizes common A-H labels; answer input
// still uses SwiftUI Picker/Toggle controls elsewhere.
enum PaperChoiceParser {
    private static let multipleChoiceKeywords = ["多选", "多项选择", "不定项选择"]
    private static let answerPrefixes = ["正确答案", "参考答案", "答案", "选项"]
    private static let answerSeparators = CharacterSet(
        charactersIn: " \t\r\n,，、;；/／|和及与"
    )
    private static let optionExpressions: [NSRegularExpression] = [
        #"(?m)(?:^|[\r\n])\s*[（(]?([A-Ha-hＡ-Ｈａ-ｈ])[）)]?\s*[\.．、:：]"#,
        #"[（(]([A-Ha-hＡ-Ｈａ-ｈ])[）)]\s*"#,
        #"(?:^|\s)([A-Ha-hＡ-Ｈａ-ｈ])\s*[\.．、:：]\s*"#
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    static func isMultipleChoice(questionText: String, correctAnswer: String) -> Bool {
        if multipleChoiceKeywords.contains(where: { questionText.contains($0) }) {
            return true
        }

        var answer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return false }

        for prefix in answerPrefixes where answer.hasPrefix(prefix) {
            answer.removeFirst(prefix.count)
            break
        }
        answer = answer.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: ":：")
            )
        )

        var labels: Set<String> = []
        for character in answer {
            if let label = normalizedLabel(String(character)) {
                labels.insert(label)
                continue
            }
            guard character.unicodeScalars.allSatisfy(answerSeparators.contains) else {
                return false
            }
        }
        return labels.count > 1
    }

    static func optionLabels(in text: String, questionType: QuestionType) -> [String] {
        guard !text.isEmpty else {
            return questionType == .choice ? ["A", "B", "C", "D"] : []
        }
        let searchRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var matches: [(location: Int, label: String)] = []

        for expression in optionExpressions {
            for match in expression.matches(in: text, range: searchRange) {
                guard match.numberOfRanges > 1,
                      let range = Range(match.range(at: 1), in: text),
                      let label = normalizedLabel(String(text[range])) else {
                    continue
                }
                matches.append((match.range.location, label))
            }
        }

        var seen: Set<String> = []
        let labels = matches
            .sorted { $0.location < $1.location }
            .compactMap { match -> String? in
                guard seen.insert(match.label).inserted else { return nil }
                return match.label
            }

        if labels.count >= 2 {
            return labels
        }
        return questionType == .choice ? ["A", "B", "C", "D"] : []
    }

    private static func normalizedLabel(_ value: String) -> String? {
        switch value.uppercased() {
        case "A", "Ａ": "A"
        case "B", "Ｂ": "B"
        case "C", "Ｃ": "C"
        case "D", "Ｄ": "D"
        case "E", "Ｅ": "E"
        case "F", "Ｆ": "F"
        case "G", "Ｇ": "G"
        case "H", "Ｈ": "H"
        default: nil
        }
    }
}
