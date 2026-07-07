import Foundation

enum VocabularyDelimitedTextParser {
    static func parse(
        _ text: String,
        delimiter: Character,
        markdown: Bool = false
    ) -> [VocabularyImportRow] {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        if markdown, lines.count >= 2 { lines.removeFirst(2) }

        return lines.enumerated().map { index, line in
            VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: VocabularyTextRowBuilder.split(
                    normalizedMarkdownLine(line, markdown: markdown),
                    delimiter: delimiter
                )
            )
        }
    }

    static func parseDash(_ text: String) -> [VocabularyImportRow] {
        text.split(separator: "\n", omittingEmptySubsequences: true).enumerated().map { index, rawLine in
            let line = String(rawLine)
            guard let range = dashSeparatorRange(in: line) else {
                return VocabularyTextRowBuilder.invalidRow(
                    index: index,
                    term: line,
                    error: "未找到两侧带空格的横线分隔符"
                )
            }
            return VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: [
                    String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces),
                    String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                ]
            )
        }
    }

    static func parseColon(_ text: String) -> [VocabularyImportRow] {
        text.split(separator: "\n", omittingEmptySubsequences: true).enumerated().map { index, rawLine in
            let line = String(rawLine)
            guard let range = line.range(of: #"[:：]"#, options: .regularExpression) else {
                return VocabularyTextRowBuilder.invalidRow(
                    index: index,
                    term: line,
                    error: "未找到冒号分隔符"
                )
            }
            return VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: [
                    String(line[..<range.lowerBound]),
                    String(line[range.upperBound...])
                ]
            )
        }
    }

    static func parseCSV(_ text: String) -> [VocabularyImportRow] {
        text.split(separator: "\n", omittingEmptySubsequences: true).enumerated().map { index, line in
            VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: VocabularyTextRowBuilder.csvFields(String(line))
            )
        }
    }

    private static func normalizedMarkdownLine(_ line: String, markdown: Bool) -> String {
        guard markdown else { return line }
        var value = line.trimmingCharacters(in: .whitespaces)
        if value.first == "|" { value.removeFirst() }
        if value.last == "|" { value.removeLast() }
        return value
    }

    private static func dashSeparatorRange(in line: String) -> Range<String.Index>? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = dashSeparatorExpression.firstMatch(in: line, range: range) else {
            return nil
        }
        return Range(match.range, in: line)
    }

    private static let dashSeparatorExpression = try! NSRegularExpression(
        pattern: #"\s+[—–-]\s+"#
    )
}
