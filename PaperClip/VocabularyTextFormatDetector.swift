import Foundation

enum VocabularyTextFormatDetector {
    static func detectFormat(_ text: String) -> VocabularyTextFormat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if looksLikeJSON(trimmed) {
            return .json
        }

        let meaningful = trimmed.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        if looksLikeMarkdownTable(meaningful) {
            return .markdown
        }

        if let delimiterFormat = dominantDelimiterFormat(in: meaningful) {
            return delimiterFormat
        }

        if lineCount(in: meaningful, matching: #"^[^:：]{1,80}\s*[:：]\s*.+$"#) >= majorityThreshold(for: meaningful) {
            return .colon
        }

        if lineCount(in: meaningful, matching: #"\s+[—–-]\s+"#) >= majorityThreshold(for: meaningful) {
            return .dash
        }

        return .pairedLines
    }

    private static func looksLikeJSON(_ text: String) -> Bool {
        (text.hasPrefix("[") || text.hasPrefix("{"))
            && (try? JSONSerialization.jsonObject(with: Data(text.utf8))) != nil
    }

    private static func looksLikeMarkdownTable(_ lines: [String]) -> Bool {
        guard lines.count >= 2, lines[0].contains("|") else { return false }
        return lines[1]
            .replacingOccurrences(of: "|", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-: "))
            .isEmpty
    }

    private static func dominantDelimiterFormat(in lines: [String]) -> VocabularyTextFormat? {
        let candidates: [(VocabularyTextFormat, Character)] = [
            (.tab, "\t"), (.pipe, "|"), (.equals, "="), (.comma, ",")
        ]
        let scored = candidates.map { format, delimiter in
            (format, lines.filter { $0.contains(delimiter) }.count)
        }.max { $0.1 < $1.1 }
        guard let scored, scored.1 >= majorityThreshold(for: lines) else { return nil }
        return scored.0
    }

    private static func lineCount(in lines: [String], matching pattern: String) -> Int {
        lines.filter { $0.range(of: pattern, options: .regularExpression) != nil }.count
    }

    private static func majorityThreshold(for lines: [String]) -> Int {
        max(1, lines.count / 2)
    }
}
